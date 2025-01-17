import { pluginCollapsibleSections } from "@expressive-code/plugin-collapsible-sections";
import { ExpressiveCodeTheme } from "@astrojs/starlight/expressive-code";
import fs from "node:fs";
import path from "node:path";

// Define allowed paths relative to project root
const ALLOWED_PATHS = ["src/themes/expressive-code"];

function readFileSyncSafe(url) {
	if (url.protocol !== "file:") {
		throw new Error("Invalid URL protocol");
	}

	// Convert URL to filesystem path and normalize
	const filePath = path.normalize(url.pathname);

	// Ensure path is within allowed directories
	const isAllowed = ALLOWED_PATHS.some((allowedPath) =>
		filePath.includes(path.normalize(allowedPath))
	);

	if (!isAllowed) {
		throw new Error("Access to this directory is not allowed");
	}

	return fs.readFileSync(url, "utf-8");
}

const jsoncStringLight = readFileSyncSafe(
	new URL(
		"./src/themes/expressive-code/Snazzy-Light-color-theme.json",
		import.meta.url
	)
);

const jsoncStringDark = readFileSyncSafe(
	new URL(
		"./src/themes/expressive-code/aura-soft-dark-soft-text-color-theme.json",
		import.meta.url
	)
);

const darkMode = ExpressiveCodeTheme.fromJSONString(jsoncStringDark);
const lightMode = ExpressiveCodeTheme.fromJSONString(jsoncStringLight);

/** @type {import('@astrojs/starlight/expressive-code').StarlightExpressiveCodeOptions} */
export default {
	// Example: Using a custom plugin (which makes this `ec.config.mjs` file necessary)
	plugins: [pluginCollapsibleSections()],
	defaultProps: {
		collapseStyle: "collapsible-start",
		frame: "none",
	},
	themes: [darkMode, lightMode],
	tabWidth: 0,
	styleOverrides: {
		borderRadius: "0.1rem",
		frames: {
			shadowColor: "none",
		},
	},
};
