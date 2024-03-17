import { useEffect } from "react";

const AdvMd = ({ children }) => {
	const advanced = JSON.parse(window.localStorage.getItem("advanced"));

	useEffect(() => {
		const AdvancedTitleList = [];
		const AdvancedTocList = [];
		const DefaultTocList = [];

		const HideTheseTocs = document.querySelectorAll(
			"#Advanced-class h1,#Advanced-class h2,#Advanced-class h3,#Advanced-class h4,#Advanced-class h5,#Advanced-class h6"
		);

		if (HideTheseTocs !== null) {
			for (let i = 0; i < HideTheseTocs.length; i++) {
				let AdvancedTitleId = HideTheseTocs[i].id;
				AdvancedTitleList.push("#" + AdvancedTitleId);
			}
		}

		const AdvancedTocHref = document.querySelectorAll("nav ul li a");

		for (let i = 0; i < AdvancedTocHref.length; i++) {
			if (AdvancedTitleList.includes(AdvancedTocHref[i].hash)) {
				AdvancedTocList.push(AdvancedTocHref[i]);
			} else {
				DefaultTocList.push(AdvancedTocHref[i]);
			}
		}

		for (let i = 0; i < DefaultTocList.length; i++) {
			DefaultTocList[i].classList.add("default-toc-show");
		}

		for (let i = 0; i < AdvancedTocList.length; i++) {
			AdvancedTocList[i].classList.add("Advanced-class");
			for (let element of document.getElementsByClassName("Advanced-class")) {
				if (advanced === false || advanced === null) {
					element.style.display = "none";
				} else {
					element.style.display = "block";
				}
			}
		}
	}, [advanced]);

	return (
		<span
			id="Advanced-class"
			className="Advanced-class"
			style={{ display: advanced ? "block" : "none" }}
		>
			{children}
		</span>
	);
};

export default AdvMd;
