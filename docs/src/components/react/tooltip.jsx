import { Tooltip } from "react-tooltip";
import "react-tooltip/dist/react-tooltip.css";

export default function MyToolTip({ html, id, label, basePath, test }) {

	const htmlSplit = html.toString().split("<hr>");
	const theme = document.documentElement.dataset.theme
	const customCssID = id;
	const glossaryUrl = basePath + "glossary/" + id;

	return (
		<>
			<a
				id={customCssID + "-tooltip"}
				data-tooltip-id={customCssID + "-tooltip"}
				data-tooltip-wrapper="span"
				target="_blank"
				className="my-tooltip-url"
				data-tooltip-html={htmlSplit[0] + '<hr class="tooltip-line">🟩 <a class="tooltip-link" href=' + glossaryUrl + ' target="_blank">Click here for the full Glossary entry</a>'}
			>
				{label}
			</a >
			<Tooltip
				noArrow="true"
				variant={theme}
				place="right"
				clickable="true"
				openOnClick="true"
				className="my-tooltip"
				id={customCssID + "-tooltip"}
				anchorSelect={"#" + customCssID + "-tooltip"}
				wrapper="span"
				positionStrategy="absolute"
			></Tooltip >
		</>
	);
}
