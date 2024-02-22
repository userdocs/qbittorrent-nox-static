// @ts-check
// Note: type annotations allow type checking and IDEs autocompletion
import fs from "node:fs/promises";
import rehypeShiki from "@shikijs/rehype";
import { bundledLanguages } from "shiki";
import {
	transformerMetaHighlight,
	transformerNotationDiff,
	transformerNotationHighlight,
	transformerNotationFocus,
} from "@shikijs/transformers";

import auraSoftDark from "./src/theme/aura-soft-dark-soft-text-color-theme.json";

const rehypeShikiPlugin = [
	rehypeShiki,
	{
		themes: {
			dark: auraSoftDark,
			light: "github-light",
		},

		transformers: [
			{
				name: "meta",
				code(node) {
					const language = this.options.lang ?? "plaintext";
					this.addClassToHast(node, `language-${language}`);
					return node;
				},
			},
			transformerMetaHighlight(),
			transformerNotationDiff(),
			transformerNotationHighlight(),
			transformerNotationFocus(),
		],

		// langs: [
		//   ...Object.keys(bundledLanguages),
		//   async () =>
		//     JSON.parse(await fs.readFile("./languages/shellscript.json", "utf-8")),
		// ],
	},
];

/** @type {import('@docusaurus/types').Config} */
const config = {
	title: "qbittorrent-nox-static.sh",
	tagline: "qBittorrent nox static binary builds using a bash script",
	favicon: "img/favicon.ico",

	// Set the production url of your site here
	url: "https://userdocs.github.io",
	// Set the /<baseUrl>/ pathname under which your site is served
	// For GitHub pages deployment, it is often '/<projectName>/'
	baseUrl: "/qbittorrent-nox-static",

	// GitHub pages deployment config.
	// If you aren't using GitHub pages, you don't need these.
	organizationName: "userdocs", // Usually your GitHub org/user name.
	projectName: "qbittorrent-nox-static", // Usually your repo name.

	onBrokenLinks: "throw",
	onBrokenMarkdownLinks: "warn",

	// Even if you don't use internalization, you can use this field to set useful
	// metadata like html lang. For example, if your site is Chinese, you may want
	// to replace "en" with "zh-Hans".
	i18n: {
		defaultLocale: "en",
		locales: ["en"],
	},

	presets: [
		[
			"classic",
			/** @type {import('@docusaurus/preset-classic').Options} */
			({
				docs: {
					sidebarPath: require.resolve("./sidebars.js"),
					// Please change this to your repo.
					// Remove this to remove the "edit this page" links.
					editUrl:
						"https://github.com/userdocs/qbittorrent-nox-static/tree/master",
					beforeDefaultRehypePlugins: [rehypeShikiPlugin],
				},
				theme: {
					customCss: require.resolve("./src/css/custom.css"),
				},
			}),
		],
	],

	plugins: [
		[
			"docusaurus-plugin-remote-content",
			{
				// options here
				noRuntimeDownloads: true,
				name: "some-content", // used by CLI, must be path safe
				sourceBaseUrl:
					"https://raw.githubusercontent.com/userdocs/qbittorrent-nox-static/master/", // the base url for the markdown (gets prepended to all of the documents when fetching)
				outDir: "docs", // the base directory to output to.
				documents: [], // the file names to download
			},
		],
	],

	themeConfig:
		/** @type {import('@docusaurus/preset-classic').ThemeConfig} */
		({
			// Replace with your project's social card
			navbar: {
				title: "Home",
				logo: {
					alt: "qbt-nox-static",
					src: "img/logo-qbittorrent.svg",
				},
				items: [
					{
						type: "docSidebar",
						sidebarId: "qtb_sidebar",
						position: "left",
						label: "Documentation",
					},
					{
						type: "custom-advanceNav",
						position: "right",
					},
					{
						href: "https://github.com/userdocs/qbittorrent-nox-static",
						label: "GitHub",
						position: "right",
					},
				],
			},
			beforeDefaultRehypePlugins: [rehypeShikiPlugin],
		}),
};

export default config;
