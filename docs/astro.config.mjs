import { defineConfig } from "astro/config";
import starlight from "@astrojs/starlight";
import react from "@astrojs/react";
import { ExpressiveCodeTheme } from "@astrojs/starlight/expressive-code";
import fs from "node:fs";

const jsoncStringLight = fs.readFileSync(
	new URL(
		`./src/themes/expressive-code/Snazzy-Light-color-theme.json`,
		import.meta.url
	),
	"utf-8"
);

const jsoncStringDark = fs.readFileSync(
	new URL(
		`./src/themes/expressive-code/aura-soft-dark-soft-text-color-theme.json`,
		import.meta.url
	),
	"utf-8"
);

const darkMode = ExpressiveCodeTheme.fromJSONString(jsoncStringDark);
const lightMode = ExpressiveCodeTheme.fromJSONString(jsoncStringLight);

// https://astro.build/config
export default defineConfig({
	site: "https://userdocs.github.io",
	base: "/qbittorrent-nox-static",
	integrations: [
		react({
			include: ["**/react/*"],
			experimentalReactChildren: true,
		}),

		starlight({
			//   favicon: "./favicon.svg",
			head: [
				// // https://starlight.astro.build/reference/configuration/#head
				// {
				//   tag: "script",
				//   content:
				//     'document.addEventListener("DOMContentLoaded", function() {document.body.classList.add("body-custom");});',
				//   defer: true,
				// },
			],
			title: "qbittorrent-nox-static",
			logo: {
				src: "./public/logo-static.svg",
			},
			components: {
				// Override the default `SocialIcons` component.
				Header: "./src/components/Header.astro",
				// Head: "./src/components/Head.astro",
			},
			expressiveCode: {
				// Pass the theme to the `themes` option
				// (consider adding a dark and light theme for accessibility)
				themes: [darkMode, lightMode],
				tabWidth: 0,
				styleOverrides: {
					// You can also override styles
					borderRadius: "0.1rem",
					frames: {
						shadowColor: "none",
					},
				},
				defaultProps: {
					frame: "none",
				},
			},

			social: {
				github: "https://github.com/userdocs/qbittorrent-nox-static",
			},
			customCss: [
				// Relative path to your custom CSS file
				"./src/styles/custom.css",
			],
			sidebar: [
				{
					label: "Read the docs",
					items: [
						// Each item here is one entry in the navigation menu.
						{
							label: "Introduction",
							link: "/introduction",
						},
						{
							label: "Prerequisites Check List",
							link: "/prerequisites",
						},
						{
							label: "Script Installation",
							link: "/script-installation",
						},
						{
							label: "Script Usage",
							link: "/script-usage",
						},
						{
							label: "Build Help",
							link: "/build-help",
						},
						{
							label: "Patching",
							link: "/patching",
						},
						{
							label: "Debugging",
							link: "/debugging",
						},
						{
							label: "Install qbittorrent",
							link: "/install-qbittorrent",
						},
						{
							label: "Nginx proxypass",
							link: "/nginx-proxypass",
						},
						{
							label: "Systemd",
							link: "/systemd",
						},
						{
							label: "Github actions",
							link: "/github-actions",
						},
						{
							label: "Change Log",
							link: "/changelog",
						},
						{
							label: "Credits",
							link: "/credits",
						},
						{
							label: "Glossary",
							link: "/glossary",
						},
					],
				},
			],
		}),
	],

	// https://discord.com/channels/830184174198718474/1070481941863878697/1211398665101516842
	vite: {
		plugins: [
			{
				name: "custom-page-props",
				transform: (code, id) => {
					if (
						id.includes("@astrojs/starlight/components/Page.astro")
					) {
						return code.replace(
							/<body/,
							'<body class="body-custom"'
						);
					}
					return code;
				},
			},
		],
	},
});
