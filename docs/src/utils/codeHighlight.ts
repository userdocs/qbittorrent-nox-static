export type HighlightLang = "bash" | "docker" | "dotenv";

function escapeHtml(text: string): string {
	return text
		.replace(/&/g, "&amp;")
		.replace(/</g, "&lt;")
		.replace(/>/g, "&gt;")
		.replace(/"/g, "&quot;");
}

function wrap(cls: string, text: string): string {
	return `<span class="tok-${cls}">${escapeHtml(text)}</span>`;
}

const BASH_CMDS = new Set([
	"docker",
	"bash",
	"curl",
	"chmod",
	"mkdir",
	"sudo",
	"env",
	"apk",
	"apt-get",
	"usermod",
	"groupmod",
	"adduser",
	"useradd",
	"printf",
]);

const DOCKER_KEYWORDS = new Set([
	"FROM",
	"RUN",
	"WORKDIR",
	"EXPOSE",
	"ENV",
	"USER",
	"CMD",
	"ARG",
	"COPY",
	"ADD",
	"ENTRYPOINT",
]);

const TOKEN_RE =
	/(#.*$)|("[^"\\]*(?:\\.[^"\\]*)*"|'[^'\\]*(?:\\.[^'\\]*)*')|(\b[A-Za-z_][A-Za-z0-9_]*=)|(\s--?[A-Za-z0-9-]+|\s\+[A-Za-z])|(\b[A-Za-z][A-Za-z0-9_-]*\b)|(\\$)/gm;

function isCommandBoundary(line: string, index: number): boolean {
	if (index === 0) return true;
	const prev = line[index - 1];
	return prev === " " || prev === "\t" || prev === "(" || prev === ";";
}

function highlightLine(line: string, lang: HighlightLang): string {
	if (!line) return "";
	if (line.trimStart().startsWith("#")) {
		return wrap("comment", line);
	}

	let out = "";
	let lastIndex = 0;
	TOKEN_RE.lastIndex = 0;

	for (const match of line.matchAll(TOKEN_RE)) {
		const index = match.index ?? 0;
		if (index > lastIndex) {
			out += escapeHtml(line.slice(lastIndex, index));
		}

		const full = match[0];
		if (match[1]) {
			out += wrap("comment", full);
		} else if (match[2]) {
			out += wrap("string", full);
		} else if (match[3]) {
			const varName = full.slice(0, -1);
			out += wrap("var", varName) + wrap("punct", "=");
		} else if (match[4]) {
			const leading = full[0];
			out += escapeHtml(leading) + wrap("flag", full.slice(1));
		} else if (match[5]) {
			if (
				lang === "docker" &&
				index === line.search(/\S/) &&
				DOCKER_KEYWORDS.has(full)
			) {
				out += wrap("keyword", full);
			} else if (
				lang !== "dotenv" &&
				isCommandBoundary(line, index) &&
				BASH_CMDS.has(full)
			) {
				out += wrap("cmd", full);
			} else {
				out += escapeHtml(full);
			}
		} else if (match[6]) {
			out += wrap("punct", full);
		} else {
			out += escapeHtml(full);
		}

		lastIndex = index + full.length;
	}

	if (lastIndex < line.length) {
		out += escapeHtml(line.slice(lastIndex));
	}

	return out;
}

/** Highlight bash, Dockerfile, or .qbt_env code safely into HTML spans. */
export function highlightCode(code: string, lang: HighlightLang): string {
	return code
		.split("\n")
		.map((line) => highlightLine(line, lang))
		.join("\n");
}
