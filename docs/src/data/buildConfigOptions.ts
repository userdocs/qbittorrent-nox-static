import type { DependencyVersions } from "../utils/qbtVersions.ts";

export type OptionChoice = {
	value: string;
	label: string;
	isOverride?: boolean;
};

export type ConfigOption = {
	variable: string;
	label: string;
	description: string;
	defaultVal: string;
	/** Concrete fallback value used when pre-filling a `Custom...` input instead of `"default"`. */
	defaultExample?: string;
	options: OptionChoice[];
	category: "basic" | "advanced";
	allowCustom?: boolean;
};

export const DOCKER_VAR_NAMES = new Set([
	"qbt_docker_base",
	"qbt_docker_port",
	"qbt_docker_volume",
	"qbt_docker_user",
]);

function withOverrideOption(
	overrideVal: string | undefined,
	prefix: string,
): OptionChoice[] {
	if (!overrideVal) return [];
	const value = `${prefix}${overrideVal}`;
	return [{ value, label: `${value} (override)`, isOverride: true }];
}

/** Build the full list of build configuration options from fetched versions and overrides. */
export function buildConfigOptions(
	versions: DependencyVersions,
	overrides: Record<string, string>,
): ConfigOption[] {
	const boostDefault = overrides.boost
		? `boost-${overrides.boost}`
		: "default";
	const libtorrentDefault = overrides.libtorrent_2_1
		? `v${overrides.libtorrent_2_1}`
		: "default";
	const qtDefault = overrides.qt6 ? `v${overrides.qt6}` : "default";
	const opensslDefault = overrides.openssl
		? `openssl-${overrides.openssl}`
		: "default";
	const qbittorrentDefault = overrides.qbittorrent
		? `release-${overrides.qbittorrent}`
		: "default";

	return [
		{
			variable: "qbt_docker_base",
			label: "Docker Base Image",
			description: "The base Docker image for the build environment",
			defaultVal: "alpine:latest",
			defaultExample: "alpine:latest",
			options: [
				{ value: "alpine:edge", label: "Alpine Edge" },
				{ value: "alpine:latest", label: "alpine:latest (recommended)" },
				{ value: "ubuntu:latest", label: "ubuntu:latest" },
				{ value: "debian:latest", label: "debian:latest" },
				{ value: "custom", label: "Custom..." },
			],
			category: "basic",
			allowCustom: true,
		},
		{
			variable: "qbt_docker_port",
			label: "Docker Port Mapping",
			description: "Port mapping for Docker container (host:container format)",
			defaultVal: "8080:8080",
			defaultExample: "8080:8080",
			options: [
				{ value: "8080:8080", label: "8080:8080" },
				{ value: "8081:8080", label: "8081:8080" },
				{ value: "9090:8080", label: "9090:8080" },
				{ value: "custom", label: "Custom..." },
			],
			category: "basic",
			allowCustom: true,
		},
		{
			variable: "qbt_docker_volume",
			label: "Docker Volume Mapping",
			description: "Volume mapping for Docker container (host:container format)",
			defaultVal: "~/qbt:/root",
			defaultExample: "~/qbt:/root",
			options: [
				{ value: "~/qbt:/root", label: "~/qbt:/root" },
				{ value: "./qbt:/root", label: "./qbt:/root" },
				{ value: "/tmp/qbt:/root", label: "/tmp/qbt:/root" },
				{ value: "custom", label: "Custom..." },
			],
			category: "basic",
			allowCustom: true,
		},
		{
			variable: "qbt_docker_user",
			label: "Docker User",
			description: "User to run the container as",
			defaultVal: "root",
			options: [
				{ value: "root", label: "root (default)" },
				{ value: "username", label: "username (1000:1000)" },
			],
			category: "basic",
		},
		{
			variable: "qbt_libtorrent_version",
			label: "Libtorrent Version",
			description:
				"Libtorrent series to use (1.2, 2.0, or 2.1). All versions use the latest Boost and OpenSSL.",
			defaultVal: "2.1",
			options: [
				{ value: "2.1", label: "2.1 (default)" },
				{ value: "2.0", label: "2.0" },
				{ value: "1.2", label: "1.2 (Legacy)" },
			],
			category: "basic",
		},
		{
			variable: "qbt_cross_name",
			label: "Target Architecture",
			description: "Cross-compilation target architecture",
			defaultVal: "",
			options: [
				{ value: "", label: "Native" },
				{ value: "aarch64", label: "aarch64" },
				{ value: "armhf", label: "armhf" },
				{ value: "armv7", label: "armv7" },
				{ value: "armel", label: "armel" },
				{ value: "x86_64", label: "x86_64" },
				{ value: "x86", label: "x86" },
				{ value: "riscv64", label: "riscv64" },
				{ value: "loongarch64", label: "loongarch64" },
				{ value: "s390x", label: "s390x" },
				{ value: "powerpc", label: "powerpc" },
				{ value: "ppc64el", label: "ppc64el" },
				{ value: "mips", label: "mips" },
				{ value: "mipsel", label: "mipsel" },
				{ value: "mips64", label: "mips64" },
				{ value: "mips64el", label: "mips64el" },
			],
			category: "basic",
		},
		{
			variable: "qbt_qbittorrent_tag",
			label: "qBittorrent Tag",
			description: "Specific qBittorrent git tag to use",
			defaultVal: qbittorrentDefault,
			defaultExample: `release-${overrides.qbittorrent || versions.qbittorrent}`,
			options: [
				...withOverrideOption(overrides.qbittorrent, "release-"),
				{
					value: "default",
					label: `release-${versions.qbittorrent} (default)`,
				},
				{ value: "custom", label: "Custom..." },
			],
			category: "basic",
			allowCustom: true,
		},
		{
			variable: "qbt_legacy_mode",
			label: "Legacy Mode",
			description: "Enable legacy build compatibility mode",
			defaultVal: "no",
			options: [
				{ value: "no", label: "No" },
				{ value: "yes", label: "Yes" },
			],
			category: "basic",
		},
		{
			variable: "qbt_advanced_view",
			label: "Script Advanced View",
			description:
				"Show all build env options in qbt.bash terminal output when running the script",
			defaultVal: "yes",
			options: [
				{ value: "yes", label: "Yes" },
				{ value: "no", label: "No" },
			],
			category: "basic",
		},
		{
			variable: "qbt_zlib_type",
			label: "Zlib Implementation",
			description: "Choose zlib implementation",
			defaultVal: "zlib",
			options: [
				{ value: "zlib", label: "zlib" },
				{ value: "zlib-ng", label: "zlib-ng" },
			],
			category: "advanced",
		},
		{
			variable: "qbt_skip_icu",
			label: "Skip ICU",
			description: "Skip International Components for Unicode",
			defaultVal: "yes",
			options: [
				{ value: "yes", label: "Yes" },
				{ value: "no", label: "No" },
			],
			category: "advanced",
		},
		{
			variable: "qbt_boost_tag",
			label: "Boost Tag",
			description: "Specific Boost library git tag to use",
			defaultVal: boostDefault,
			defaultExample: `boost-${overrides.boost || versions.boost}`,
			options: [
				...withOverrideOption(overrides.boost, "boost-"),
				{
					value: "default",
					label: `boost-${versions.boost} (default)`,
				},
				{ value: "custom", label: "Custom..." },
			],
			category: "advanced",
			allowCustom: true,
		},
		{
			variable: "qbt_libtorrent_tag",
			label: "Libtorrent Tag",
			description:
				"Specific libtorrent git tag to use (auto resolves the latest tag for the selected series)",
			defaultVal: libtorrentDefault,
			defaultExample: `v${overrides.libtorrent_2_1 || versions.libtorrent_2_1}`,
			options: [
				...withOverrideOption(overrides.libtorrent_2_1, "v"),
				{
					value: "default",
					label: `Auto — latest for series (v${versions.libtorrent_2_1})`,
				},
				...withOverrideOption(overrides.libtorrent_2_0, "v"),
				{
					value: `v${versions.libtorrent_2_0}`,
					label: `v${versions.libtorrent_2_0} (pin 2.0)`,
				},
				...withOverrideOption(overrides.libtorrent_1_2, "v"),
				{
					value: `v${versions.libtorrent_1_2}`,
					label: `v${versions.libtorrent_1_2} (pin 1.2)`,
				},
				{ value: "custom", label: "Custom..." },
			],
			category: "advanced",
			allowCustom: true,
		},
		{
			variable: "qbt_libtorrent_master_jamfile",
			label: "Use Master Jamfile",
			description: "Use libtorrent master branch jamfile",
			defaultVal: "no",
			options: [
				{ value: "no", label: "No" },
				{ value: "yes", label: "Yes" },
			],
			category: "advanced",
		},
		{
			variable: "qbt_qt_version",
			label: "Qt Version",
			description:
				"Select Qt major version (Qt 5 automatically pairs with QMake; Qt 6 uses CMake)",
			defaultVal: "6",
			options: [
				{ value: "6", label: "Qt 6 (CMake)" },
				{ value: "5", label: "Qt 5 (QMake)" },
			],
			category: "advanced",
		},
		{
			variable: "qbt_qt_tag",
			label: "Qt Tag",
			description: "Specific Qt git tag to use",
			defaultVal: qtDefault,
			defaultExample: `v${overrides.qt6 || versions.qt6}`,
			options: [
				...withOverrideOption(overrides.qt6, "v"),
				{
					value: "default",
					label: `Auto — latest for Qt version (v${versions.qt6})`,
				},
				...withOverrideOption(overrides.qt5, "v"),
				{
					value: `v${versions.qt5}`,
					label: `v${versions.qt5} (pin Qt 5 LTS)`,
				},
				{ value: "custom", label: "Custom..." },
			],
			category: "advanced",
			allowCustom: true,
		},
		{
			variable: "qbt_openssl_tag",
			label: "OpenSSL Tag",
			description: "Specific OpenSSL git tag to use",
			defaultVal: opensslDefault,
			defaultExample: `openssl-${overrides.openssl || versions.openssl}`,
			options: [
				...withOverrideOption(overrides.openssl, "openssl-"),
				{
					value: "default",
					label: `openssl-${versions.openssl} (default)`,
				},
				{ value: "custom", label: "Custom..." },
			],
			category: "advanced",
			allowCustom: true,
		},
		{
			variable: "qbt_workflow_files",
			label: "Use Workflow Files",
			description: "Use workflow dependency files",
			defaultVal: "no",
			options: [
				{ value: "no", label: "No" },
				{ value: "yes", label: "Yes" },
			],
			category: "advanced",
		},
		{
			variable: "qbt_build_debug",
			label: "Debug Build",
			description:
				"Build with debug information - overrides strip binary options",
			defaultVal: "no",
			options: [
				{ value: "no", label: "No" },
				{ value: "yes", label: "Yes" },
			],
			category: "advanced",
		},
		{
			variable: "qbt_standard",
			label: "C++ Standard",
			description:
				"C++ language standard (resolved automatically by qbt.bash based on app and Qt versions)",
			defaultVal: "default",
			options: [
				{ value: "default", label: "Auto (script-resolved)" },
				{ value: "14", label: "C++14" },
				{ value: "17", label: "C++17" },
				{ value: "20", label: "C++20" },
				{ value: "23", label: "C++23" },
			],
			category: "advanced",
		},
		{
			variable: "qbt_optimise",
			label: "Optimizations",
			description: "Enable additional compiler optimizations",
			defaultVal: "no",
			options: [
				{ value: "no", label: "No" },
				{ value: "yes", label: "Yes" },
			],
			category: "advanced",
		},
		{
			variable: "qbt_use_lto",
			label: "Use LTO",
			description:
				"Link-Time Optimization (script defaults to Yes for native/Debian/Ubuntu, No for Alpine cross unless using musl-cross-make)",
			defaultVal: "default",
			options: [
				{ value: "default", label: "Auto (script default)" },
				{ value: "yes", label: "Yes" },
				{ value: "no", label: "No" },
			],
			category: "advanced",
		},
		{
			variable: "qbt_with_qemu",
			label: "Use QEMU",
			description: "Use QEMU for cross-compilation testing",
			defaultVal: "yes",
			options: [
				{ value: "yes", label: "Yes" },
				{ value: "no", label: "No" },
			],
			category: "advanced",
		},
		{
			variable: "qbt_host_deps",
			label: "Host Dependencies",
			description: "Build host dependencies",
			defaultVal: "no",
			options: [
				{ value: "yes", label: "Yes" },
				{ value: "no", label: "No" },
			],
			category: "advanced",
		},
		{
			variable: "qbt_build_dir",
			label: "Build Directory",
			description: "Directory name for build files",
			defaultVal: "qbt-build",
			defaultExample: "qbt-build",
			options: [
				{ value: "qbt-build", label: "qbt-build" },
				{ value: "build", label: "build" },
				{ value: "custom", label: "Custom..." },
			],
			category: "advanced",
			allowCustom: true,
		},
		{
			variable: "qbt_build_tool",
			label: "Build Tool",
			description:
				"Build system to use (CMake pairs with Qt 6; QMake pairs with Qt 5)",
			defaultVal: "cmake",
			options: [
				{ value: "cmake", label: "CMake (Qt 6)" },
				{ value: "qmake", label: "QMake (Qt 5)" },
			],
			category: "advanced",
		},
		{
			variable: "qbt_mcm_url",
			label: "Musl Cross Make URL",
			description: "GitHub repository for musl cross make toolchain",
			defaultVal: "userdocs/qbt-musl-cross-make",
			defaultExample: "userdocs/qbt-musl-cross-make",
			options: [
				{
					value: "userdocs/qbt-musl-cross-make",
					label: "userdocs/qbt-musl-cross-make",
				},
				{
					value: "userdocs/musl-cross-make",
					label: "userdocs/musl-cross-make",
				},
				{ value: "custom", label: "Custom..." },
			],
			category: "advanced",
			allowCustom: true,
		},
		{
			variable: "qbt_patches_url",
			label: "Patches URL",
			description: "GitHub repository for patches",
			defaultVal: "userdocs/qbittorrent-nox-static",
			defaultExample: "userdocs/qbittorrent-nox-static",
			options: [
				{
					value: "userdocs/qbittorrent-nox-static",
					label: "userdocs/qbittorrent-nox-static",
				},
				{ value: "custom", label: "Custom..." },
			],
			category: "advanced",
			allowCustom: true,
		},
		{
			variable: "qbt_cache_dir",
			label: "Cache Directory",
			description: "Directory for build cache (empty for no cache)",
			defaultVal: "",
			defaultExample: ".cache",
			options: [
				{ value: "", label: "None" },
				{ value: ".cache", label: ".cache" },
				{ value: "/tmp/qbt-cache", label: "/tmp/qbt-cache" },
				{ value: "custom", label: "Custom..." },
			],
			category: "advanced",
			allowCustom: true,
		},
		{
			variable: "qbt_optimise_strip",
			label: "Optimize Strip",
			description: "Strip debug symbols for smaller binaries",
			defaultVal: "yes",
			options: [
				{ value: "yes", label: "Yes" },
				{ value: "no", label: "No" },
			],
			category: "advanced",
		},
		{
			variable: "qbt_static_ish",
			label: "Static-ish Build",
			description: "Build with static-ish linking",
			defaultVal: "no",
			options: [
				{ value: "yes", label: "Yes" },
				{ value: "no", label: "No" },
			],
			category: "advanced",
		},
		{
			variable: "qbt_host_deps_repo",
			label: "Host Dependencies Repository",
			description: "GitHub repository for host dependencies",
			defaultVal: "userdocs/qbt-host-deps",
			defaultExample: "userdocs/qbt-host-deps",
			options: [
				{ value: "userdocs/qbt-host-deps", label: "userdocs/qbt-host-deps" },
				{ value: "custom", label: "Custom..." },
			],
			category: "advanced",
			allowCustom: true,
		},
	];
}
