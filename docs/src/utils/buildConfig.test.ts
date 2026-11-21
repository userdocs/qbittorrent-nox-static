import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
	FALLBACK_VERSIONS,
	isSafeTagValue,
	parseOverrides,
} from "./qbtVersions.ts";
import { buildConfigOptions } from "../data/buildConfigOptions.ts";
import {
	collectScriptEnvVars,
	generateAllOutputs,
	isOptionModified,
	quoteShellArg,
	type BuildConfigState,
} from "./buildCommandGenerator.ts";
import { highlightCode } from "./codeHighlight.ts";

function createDefaultState(
	overrides: Record<string, string> = {},
): BuildConfigState {
	const options = buildConfigOptions(FALLBACK_VERSIONS, overrides);
	const values: Record<string, string> = {};
	const defaults: Record<string, string> = {};
	const overrideSet = new Set<string>();

	for (const opt of options) {
		values[opt.variable] = opt.defaultVal;
		defaults[opt.variable] = opt.defaultVal;
		const selected = opt.options.find((o) => o.value === opt.defaultVal);
		if (selected?.isOverride) overrideSet.add(opt.variable);
	}

	return { values, defaults, overrides: overrideSet };
}

describe("parseOverrides & validation", () => {
	it("ignores comments, blank lines, prototype keys, and unsafe tag values", () => {
		const raw = [
			'# current_github_tag[openssl]="3.6.2"',
			"",
			'current_github_tag[boost]="1.93.0"',
			'current_github_tag[__proto__]="polluted"',
			'current_github_tag[qt6]="6.12.0; rm -rf /"',
			'  current_github_tag[libtorrent_2_1]="2.1.3"  ',
		].join("\r\n");

		assert.deepEqual(parseOverrides(raw), {
			boost: "1.93.0",
			libtorrent_2_1: "2.1.3",
		});
		assert.equal(isSafeTagValue("v2.1.2"), true);
		assert.equal(isSafeTagValue("$(whoami)"), false);
	});
});

describe("buildConfigOptions", () => {
	it("contains unique variable names and all 15 supported cross architectures", () => {
		const options = buildConfigOptions(FALLBACK_VERSIONS, {});
		const names = options.map((o) => o.variable);
		assert.equal(new Set(names).size, names.length);
		assert.equal(
			names.filter((n) => n === "qbt_qbittorrent_tag").length,
			1,
		);

		const cross = options.find((o) => o.variable === "qbt_cross_name");
		assert.ok(cross);
		assert.equal(cross.options.length, 16); // Native + 15 cross arches
		assert.ok(cross.options.some((o) => o.value === "riscv64"));
		assert.ok(cross.options.some((o) => o.value === "loongarch64"));
	});

	it("supports libtorrent 1.2, 2.0, and 2.1 with no boost 1.86.0 cap", () => {
		const options = buildConfigOptions(FALLBACK_VERSIONS, {});
		const ltVer = options.find((o) => o.variable === "qbt_libtorrent_version");
		assert.ok(ltVer);
		assert.equal(ltVer.defaultVal, "2.1");
		assert.deepEqual(
			ltVer.options.map((o) => o.value),
			["2.1", "2.0", "1.2"],
		);

		const boostTag = options.find((o) => o.variable === "qbt_boost_tag");
		assert.ok(boostTag);
		assert.equal(
			boostTag.options.some((o) => o.value === "boost-1.86.0"),
			false,
		);
	});

	it("uses Auto defaults for qbt_use_lto and qbt_standard and concrete defaultExample on tag fields", () => {
		const options = buildConfigOptions(FALLBACK_VERSIONS, {});
		const lto = options.find((o) => o.variable === "qbt_use_lto");
		const std = options.find((o) => o.variable === "qbt_standard");
		const qbtTag = options.find((o) => o.variable === "qbt_qbittorrent_tag");
		assert.equal(lto?.defaultVal, "default");
		assert.equal(std?.defaultVal, "default");
		assert.equal(qbtTag?.defaultExample, `release-${FALLBACK_VERSIONS.qbittorrent}`);
	});
});

describe("buildCommandGenerator security & output", () => {
	it("generates clean default outputs and .qbt_env hint when unmodified", () => {
		const state = createDefaultState();
		assert.deepEqual(collectScriptEnvVars(state), []);

		const outputs = generateAllOutputs(state);
		assert.equal(
			outputs.native,
			"bash <(curl -sL https://usrdx.github.io/s/qbt.bash) bootstrap_deps all",
		);
		assert.match(outputs.qbtEnv, /All options currently match script defaults/);
	});

	it("escapes shell metacharacters and strips newlines in custom env, Docker, and Dockerfile outputs", () => {
		const state = createDefaultState();
		state.values.qbt_cache_dir = '/tmp/my cache/$(whoami)`id`\nRUN evil';
		state.values.qbt_docker_volume = "~/my builds:/root";
		state.values.qbt_docker_port = "9000:8080\nRUN evil";
		state.values.qbt_docker_base = "alpine:latest\nRUN curl evil";

		const outputs = generateAllOutputs(state);
		assert.ok(outputs.native.includes('qbt_cache_dir="/tmp/my cache/\\$(whoami)\\`id\\`RUN evil"'));
		assert.ok(outputs.qbtEnv.includes('qbt_cache_dir="/tmp/my cache/\\$(whoami)\\`id\\`RUN evil"'));
		assert.equal(outputs.dockerfile.includes("\nRUN evil"), false);
		assert.equal(outputs.dockerfile.includes("\nRUN curl evil"), false);
		assert.ok(outputs.dockerfile.includes("EXPOSE 8080")); // invalid port falls back safely
		assert.ok(outputs.docker.includes("-v ~/'my builds:/root'"));
		assert.ok(outputs.dockerLocal.includes("mkdir -p ~/'my builds'"));
	});

	it("quotes shell arguments cleanly while keeping ~/ tilde expansion", () => {
		assert.equal(quoteShellArg("~/qbt"), "~/qbt");
		assert.equal(quoteShellArg("~/my builds"), "~/'my builds'");
		assert.equal(quoteShellArg("/tmp/a b"), "'/tmp/a b'");
		assert.equal(quoteShellArg("it's/dir"), "'it'\\''s/dir'");
	});

	it("ensures /home/username directory creation & ownership for Ubuntu and Alpine username mode", () => {
		const state = createDefaultState();
		state.values.qbt_docker_base = "ubuntu:latest";
		state.values.qbt_docker_user = "username";

		const outputs = generateAllOutputs(state);
		assert.match(outputs.dockerfile, /mkdir -p \/home\/username/);
		assert.match(outputs.dockerfile, /chown username:username \/home\/username/);
		assert.match(outputs.dockerfile, /USER username/);
	});

	it("never emits 'default' literal when an override is active and user switches to default", () => {
		const state = createDefaultState({ boost: "1.93.0" });
		assert.deepEqual(collectScriptEnvVars(state), ['qbt_boost_tag="boost-1.93.0"']);

		state.values.qbt_boost_tag = "default";
		state.overrides.delete("qbt_boost_tag");
		assert.deepEqual(collectScriptEnvVars(state), []);
	});

	it("tracks option modified status accurately", () => {
		assert.equal(isOptionModified("default", "default", false), false);
		assert.equal(isOptionModified("boost-1.93.0", "boost-1.93.0", true), true);
		assert.equal(isOptionModified("2.0", "2.1", false), true);
		assert.equal(isOptionModified("", "~/qbt:/root", false), false);
	});
});

describe("highlightCode", () => {
	it("escapes HTML characters and only highlights commands at command boundaries", () => {
		const html = highlightCode(
			'mkdir -p ~/run && bash <(curl -sL https://example.com) && qbt_test="ok"',
			"bash",
		);
		assert.ok(html.includes("&lt;("));
		assert.ok(html.includes('tok-cmd">mkdir</span>'));
		assert.ok(html.includes('tok-cmd">bash</span>'));
		assert.ok(html.includes('tok-cmd">curl</span>'));
		assert.equal(html.includes('tok-cmd">run</span>'), false);
		assert.ok(html.includes('tok-var">qbt_test</span>'));
		assert.ok(html.includes('tok-string">&quot;ok&quot;</span>'));
	});
});
