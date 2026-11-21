import { DOCKER_VAR_NAMES } from "../data/buildConfigOptions.ts";

export interface BuildConfigState {
	values: Record<string, string>;
	defaults: Record<string, string>;
	overrides: Set<string>;
}

export interface GeneratedOutputs {
	native: string;
	local: string;
	docker: string;
	dockerLocal: string;
	dockerfile: string;
	qbtEnv: string;
}

const SCRIPT_URL = "https://usrdx.github.io/s/qbt.bash";
const SAFE_UNQUOTED_RE = /^[A-Za-z0-9_./:@=+-]+$/;
const SAFE_EXPOSED_PORT_RE = /^\d{1,5}(?:\/(?:tcp|udp))?$/;
const SAFE_VAR_NAME_RE = /^qbt_[a-z0-9_]+$/;

function sanitizeSingleLine(value: string): string {
	return value.replace(/[\r\n\0]+/g, "").trim();
}

/** Escape characters interpreted inside bash double quotes (`\`, `"`, `$`, `` ` ``). */
function escapeDoubleQuotedShell(value: string): string {
	return sanitizeSingleLine(value)
		.replace(/\\/g, "\\\\")
		.replace(/"/g, '\\"')
		.replace(/\$/g, "\\$")
		.replace(/`/g, "\\`");
}

function escapeSingleQuotes(value: string): string {
	return value.replace(/'/g, "'\\''");
}

/** Quote a shell argument safely while preserving `~/` tilde expansion when present. */
export function quoteShellArg(rawArg: string): string {
	const arg = sanitizeSingleLine(rawArg);
	if (!arg) return "''";
	if (SAFE_UNQUOTED_RE.test(arg)) return arg;
	if (arg === "~") return "~";
	if (arg.startsWith("~/")) {
		const rest = arg.slice(2);
		if (!rest) return "~/";
		if (SAFE_UNQUOTED_RE.test(rest)) return arg;
		return `~/'${escapeSingleQuotes(rest)}'`;
	}
	return `'${escapeSingleQuotes(arg)}'`;
}

/** Single source of truth for whether a variable differs from its default state. */
export function isOptionModified(
	currentValue: string,
	defaultValue: string,
	isOverrideSelected: boolean,
): boolean {
	const trimmed = sanitizeSingleLine(currentValue);
	if (trimmed === "" || trimmed === "default") {
		return trimmed !== defaultValue && defaultValue !== "" && defaultValue !== "default"
			? isOverrideSelected
			: false;
	}
	return trimmed !== defaultValue || isOverrideSelected;
}

/** Collect non-Docker script environment variables that differ from defaults (or are active overrides). */
export function collectScriptEnvVars(state: BuildConfigState): string[] {
	const vars: string[] = [];
	for (const [variable, rawCur] of Object.entries(state.values)) {
		if (!SAFE_VAR_NAME_RE.test(variable) || DOCKER_VAR_NAMES.has(variable)) {
			continue;
		}
		const def = state.defaults[variable] ?? "";
		const cur = sanitizeSingleLine(rawCur);
		const isOverride = state.overrides.has(variable);
		if (cur === "" || cur === "default") continue;
		if (cur !== def || isOverride) {
			vars.push(`${variable}="${escapeDoubleQuotedShell(cur)}"`);
		}
	}
	return vars;
}

function getScriptSubcommand(state: BuildConfigState): string {
	return state.values.qbt_legacy_mode === "yes" ? "all" : "bootstrap_deps all";
}

function getScriptCommand(state: BuildConfigState, isLocal = false): string {
	const sub = getScriptSubcommand(state);
	return isLocal ? `./qbt.bash ${sub}` : `bash <(curl -sL ${SCRIPT_URL}) ${sub}`;
}

interface DockerResolvedConfig {
	baseImage: string;
	packageManager: string;
	shell: string;
	portMapping: string;
	exposedPort: string;
	volumeMapping: string;
	hostVolumeDir: string;
	dockerUser: string;
	envVars: string[];
}

function resolveHostVolumeDir(volumeMapping: string): string {
	const lastColon = volumeMapping.lastIndexOf(":");
	if (lastColon <= 0) return volumeMapping || "~/qbt";
	return volumeMapping.slice(0, lastColon);
}

function resolveExposedPort(rawPort: string): string {
	const trimmed = sanitizeSingleLine(rawPort);
	if (!trimmed) return "8080";
	const lastSegment = trimmed.split(":").pop()?.trim() ?? "";
	return SAFE_EXPOSED_PORT_RE.test(lastSegment) ? lastSegment : "8080";
}

function resolveDockerConfig(state: BuildConfigState): DockerResolvedConfig {
	const baseImage =
		sanitizeSingleLine(state.values.qbt_docker_base ?? "") ||
		state.defaults.qbt_docker_base ||
		"alpine:latest";
	const portMapping =
		sanitizeSingleLine(state.values.qbt_docker_port ?? "") ||
		state.defaults.qbt_docker_port ||
		"8080:8080";
	let volumeMapping =
		sanitizeSingleLine(state.values.qbt_docker_volume ?? "") ||
		state.defaults.qbt_docker_volume ||
		"~/qbt:/root";
	const dockerUser =
		sanitizeSingleLine(state.values.qbt_docker_user ?? "") ||
		state.defaults.qbt_docker_user ||
		"root";

	const isDebianFamily =
		baseImage.includes("ubuntu") || baseImage.includes("debian");

	let packageManager = isDebianFamily
		? "apt-get update && \\\n\tapt-get install -y git curl"
		: "apk update && apk add bash git curl";
	const shell = isDebianFamily ? "/bin/bash" : "/bin/ash";

	if (dockerUser === "username") {
		packageManager = packageManager.replace("git curl", "git curl sudo");
		if (volumeMapping.includes(":/root")) {
			volumeMapping = volumeMapping.replace(":/root", ":/home/username");
		}
	}

	return {
		baseImage,
		packageManager,
		shell,
		portMapping,
		exposedPort: resolveExposedPort(portMapping),
		volumeMapping,
		hostVolumeDir: resolveHostVolumeDir(volumeMapping),
		dockerUser,
		envVars: collectScriptEnvVars(state),
	};
}

function getUserSetupCmds(baseImage: string, dockerUser: string): string[] {
	if (dockerUser !== "username") return [];
	const sudoersLine =
		'printf "%s" "username ALL=(ALL) SETENV: NOPASSWD: ALL" > /etc/sudoers.d/username';
	if (baseImage.includes("ubuntu")) {
		return [
			"usermod -l username -d /home/username ubuntu",
			"groupmod -n username ubuntu",
			"mkdir -p /home/username",
			"chown username:username /home/username",
			sudoersLine,
			"chmod 0440 /etc/sudoers.d/username",
		];
	}
	if (baseImage.includes("alpine")) {
		return [
			"adduser -h /home/username -Ds /bin/bash -u 1000 username",
			"chown username:username /home/username",
			sudoersLine,
			"chmod 0440 /etc/sudoers.d/username",
		];
	}
	return [
		"useradd -ms /bin/bash -u 1000 username",
		"chown username:username /home/username",
		sudoersLine,
		"chmod 0440 /etc/sudoers.d/username",
	];
}

export function generateNativeCommand(state: BuildConfigState): string {
	const vars = collectScriptEnvVars(state);
	const cmd = getScriptCommand(state, false);
	if (!vars.length) return cmd;
	return `${vars.map((v) => `${v} \\`).join("\n")}\n${cmd}`;
}

export function generateLocalCommand(state: BuildConfigState): string {
	const vars = collectScriptEnvVars(state);
	const download = `curl -sL ${SCRIPT_URL} -o qbt.bash && \\\nchmod +x qbt.bash`;
	const cmd = getScriptCommand(state, true);
	if (!vars.length) return `${download}\n${cmd}`;
	return `${download}\n${vars.map((v) => `${v} \\`).join("\n")}\n${cmd}`;
}

export function generateDockerCommand(
	state: BuildConfigState,
	isLocal: boolean,
): string {
	const {
		baseImage,
		packageManager,
		shell,
		portMapping,
		volumeMapping,
		hostVolumeDir,
		dockerUser,
		envVars,
	} = resolveDockerConfig(state);

	const setupCmds = getUserSetupCmds(baseImage, dockerUser);
	const userSetup = setupCmds.length
		? ` && \\\n    ${setupCmds.join(" && \\\n    ")}`
		: "";
	const workDir = dockerUser === "username" ? "/home/username" : "/root";
	const isUser = dockerUser === "username";

	let scriptCmd: string;
	if (isLocal) {
		const scriptPath = `${workDir}/qbt.bash`;
		const baseCmd = `bash ${scriptPath} ${getScriptSubcommand(state)}`;
		scriptCmd = isUser
			? `sudo -E -H -u username env HOME=/home/username ${baseCmd}`
			: baseCmd;
	} else {
		const baseCmd = getScriptCommand(state, false);
		scriptCmd = isUser
			? `sudo -E -H -u username bash -c "HOME=/home/username ${baseCmd}"`
			: baseCmd;
	}

	const quotedHostDir = quoteShellArg(hostVolumeDir);
	const quotedDownloadTarget = quoteShellArg(`${hostVolumeDir}/qbt.bash`);
	const downloadLine = isLocal
		? `mkdir -p ${quotedHostDir} && chmod 755 ${quotedHostDir} && \\\ncurl -sL ${SCRIPT_URL} -o ${quotedDownloadTarget} && \\\n`
		: "";

	const envBlock = envVars.map((v) => `\t-e ${v} \\\n`).join("");
	const innerShellCmd = escapeSingleQuotes(
		`${packageManager}${userSetup} && \\\n\t${scriptCmd}`,
	);

	return (
		`${downloadLine}docker run -it -w ${workDir} \\\n` +
		`\t-p ${quoteShellArg(portMapping)} \\\n` +
		`\t-v ${quoteShellArg(volumeMapping)} \\\n` +
		`${envBlock}` +
		`\t${quoteShellArg(baseImage)} ${shell} -c \\\n` +
		`\t'${innerShellCmd}'`
	);
}

export function generateDockerfile(state: BuildConfigState): string {
	const { baseImage, exposedPort, dockerUser, envVars } =
		resolveDockerConfig(state);

	const safeBaseImage = baseImage.replace(/\s+/g, "") || "alpine:latest";
	const isDebianFamily =
		safeBaseImage.includes("ubuntu") || safeBaseImage.includes("debian");
	let pkgMgr = isDebianFamily
		? "apt-get update && \\\n    apt-get install -y git curl"
		: "apk update && apk add bash git curl";
	if (dockerUser === "username") {
		pkgMgr = pkgMgr.replace("git curl", "git curl sudo");
	}

	const workDir = dockerUser === "username" ? "/home/username" : "/root";
	const setupCmds = getUserSetupCmds(safeBaseImage, dockerUser);
	const userSetupBlock = setupCmds.length
		? `\n\n# Set up username user\nRUN ${setupCmds.join(" && \\\n    ")}`
		: "";

	const envSection = envVars.length
		? `\n\n# Environment variables\nENV ${envVars
				.map((e, i) => (i < envVars.length - 1 ? `${e} \\` : e))
				.join("\n    ")}`
		: "";

	const userSection = dockerUser === "username" ? "\n\nUSER username" : "";
	const cmdArgs =
		state.values.qbt_legacy_mode === "yes"
			? `"all"`
			: `"bootstrap_deps", "all"`;

	return (
		`FROM ${safeBaseImage}\n\n` +
		`# Install dependencies\nRUN ${pkgMgr}${userSetupBlock}\n\n` +
		`# Download build script\nRUN curl -sL ${SCRIPT_URL} -o /usr/local/bin/qbt.bash && \\\n    chmod +x /usr/local/bin/qbt.bash\n\n` +
		`WORKDIR ${workDir}\n\n` +
		`EXPOSE ${exposedPort}` +
		`${envSection}` +
		`${userSection}\n\n` +
		`# Run build\nCMD ["qbt.bash", ${cmdArgs}]`
	);
}

export function generateQbtEnv(state: BuildConfigState): string {
	const vars = collectScriptEnvVars(state);
	if (!vars.length) {
		return [
			"# .qbt_env — place in the same directory as qbt.bash",
			"# All options currently match script defaults.",
			"# Modify any setting above to populate .qbt_env, or run: ./qbt.bash -bs-e",
		].join("\n");
	}
	return [
		"# .qbt_env — place in the same directory as qbt.bash",
		...vars,
	].join("\n");
}

export function generateAllOutputs(state: BuildConfigState): GeneratedOutputs {
	return {
		native: generateNativeCommand(state),
		local: generateLocalCommand(state),
		docker: generateDockerCommand(state, false),
		dockerLocal: generateDockerCommand(state, true),
		dockerfile: generateDockerfile(state),
		qbtEnv: generateQbtEnv(state),
	};
}
