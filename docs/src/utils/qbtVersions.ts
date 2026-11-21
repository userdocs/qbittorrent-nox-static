export interface DependencyVersions {
	boost: string;
	libtorrent_1_2: string;
	libtorrent_2_0: string;
	libtorrent_2_1: string;
	openssl: string;
	qt5: string;
	qt6: string;
	qbittorrent: string;
}

export interface RemoteBuildData {
	versions: DependencyVersions;
	overrides: Record<string, string>;
}

const DEPENDENCY_VERSIONS_URL =
	"https://github.com/userdocs/qbt-workflow-files/releases/latest/download/dependency-version.json";
const OVERRIDES_URL =
	"https://raw.githubusercontent.com/userdocs/qbt-workflow-files/refs/heads/main/overrides";

const SAFE_KEY_RE = /^[A-Za-z0-9._-]+$/;
const SAFE_TAG_VALUE_RE = /^[A-Za-z0-9._+/~:-]+$/;
const FORBIDDEN_KEYS = new Set(["__proto__", "constructor", "prototype"]);

export const FALLBACK_VERSIONS: DependencyVersions = {
	boost: "1.92.0",
	libtorrent_1_2: "1.2.20",
	libtorrent_2_0: "2.0.15",
	libtorrent_2_1: "2.1.2",
	openssl: "4.1.0",
	qt5: "5.15.19",
	qt6: "6.12.0",
	qbittorrent: "5.3.0",
};

export function isSafeTagValue(value: string): boolean {
	return value.length > 0 && value.length <= 128 && SAFE_TAG_VALUE_RE.test(value);
}

/** Parse active `current_github_tag[key]="value"` lines, ignoring `#` comments and unsafe values. */
export function parseOverrides(text: string): Record<string, string> {
	const overrides = Object.create(null) as Record<string, string>;
	for (const rawLine of text.split(/\r?\n/)) {
		const line = rawLine.trim();
		if (!line || line.startsWith("#")) continue;
		const match = line.match(/^current_github_tag\[([^\]]+)\]="([^"]+)"/);
		if (!match) continue;
		const key = match[1].trim();
		const val = match[2].trim();
		if (
			SAFE_KEY_RE.test(key) &&
			!FORBIDDEN_KEYS.has(key) &&
			isSafeTagValue(val)
		) {
			overrides[key] = val;
		}
	}
	return { ...overrides };
}

async function safeFetchText(url: string, timeoutMs = 5000): Promise<string | null> {
	try {
		const res = await fetch(url, { signal: AbortSignal.timeout(timeoutMs) });
		if (!res.ok) return null;
		return await res.text();
	} catch {
		return null;
	}
}

/** Fetch dependency versions and workflow overrides with resilient fallbacks and validation. */
export async function fetchRemoteBuildData(): Promise<RemoteBuildData> {
	const [versionsText, overridesText] = await Promise.all([
		safeFetchText(DEPENDENCY_VERSIONS_URL),
		safeFetchText(OVERRIDES_URL),
	]);

	const versions: DependencyVersions = { ...FALLBACK_VERSIONS };
	if (versionsText) {
		try {
			const parsed = JSON.parse(versionsText) as Record<string, unknown>;
			if (parsed && typeof parsed === "object" && !Array.isArray(parsed)) {
				for (const key of Object.keys(FALLBACK_VERSIONS) as Array<
					keyof DependencyVersions
				>) {
					const value = parsed[key];
					if (typeof value === "string") {
						const trimmed = value.trim();
						if (isSafeTagValue(trimmed)) {
							versions[key] = trimmed;
						}
					}
				}
			}
		} catch {
			// Keep fallback versions if remote payload is malformed
		}
	}

	const overrides = overridesText ? parseOverrides(overridesText) : {};
	return { versions, overrides };
}
