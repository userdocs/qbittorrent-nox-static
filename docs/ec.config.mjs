import { pluginCollapsibleSections } from "@expressive-code/plugin-collapsible-sections";
import { ExpressiveCodeTheme } from "@astrojs/starlight/expressive-code";
import { readFileSync } from "node:fs";

// Load theme files as raw strings (supports JSON with comments/trailing commas)
const jsoncStringLight = readFileSync(
	"./src/themes/expressive-code/Snazzy-Light-color-theme.json",
	"utf-8"
);
const jsoncStringDark = readFileSync(
	"./src/themes/expressive-code/aura-soft-dark-soft-text-color-theme.json",
	"utf-8"
);

// Create themes from raw JSONC strings
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
