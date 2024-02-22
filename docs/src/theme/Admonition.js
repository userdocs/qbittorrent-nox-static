import React from "react";
import Admonition from "@theme-original/Admonition";
import Light from "@site/static/img/admonition-primary-light.svg";
import Dark from "@site/static/img/admonition-primary-dark.svg";
import Grey from "@site/static/img/admonition-grey.svg";
import Green from "@site/static/img/admonition-green.svg";
import Blue from "@site/static/img/admonition-blue.svg";
import Orange from "@site/static/img/admonition-orange.svg";
import Red from "@site/static/img/admonition-red.svg";
import { useColorMode } from "@docusaurus/theme-common";

export default function AdmonitionWrapper(props) {
  const { colorMode } = useColorMode();
  if (props.type == "note" && colorMode === "dark") {
    return <Admonition icon={<Dark />} {...props} />;
  }

  if (props.type == "note" && colorMode === "light") {
    return <Admonition icon={<Light />} {...props} />;
  }
  if (props.type == "tip") {
    return <Admonition icon={<Green />} {...props} />;
  }
  if (props.type == "info") {
    return <Admonition icon={<Blue />} {...props} />;
  }
  if (props.type == "caution") {
    return <Admonition icon={<Orange />} {...props} />;
  }
  if (props.type == "warning") {
    return <Admonition icon={<Orange />} {...props} />;
  }
  if (props.type == "danger") {
    return <Admonition icon={<Red />} {...props} />;
  }
  return <Admonition icon="" {...props} />;
}
