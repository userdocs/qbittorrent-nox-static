import { defineConfig } from "astro/config";
import starlight from "@astrojs/starlight";
import starlightImageZoom from "starlight-image-zoom";

// https://astro.build/config
export default defineConfig({
	site: "https://userdocs.github.io",
	base: "/qbittorrent-nox-static",
	integrations: [
		starlight({
			plugins: [starlightImageZoom()],
			title: "qbittorrent-nox-static",
			logo: {
				src: "./public/logo-static.svg",
			},
			components: {
				Header: "./src/components/Header.astro",
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
							label: "Github - Artifact Attestations",
							link: "/artifact-attestations",
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
