import React from "react";
import clsx from "clsx";
import Heading from "@theme/Heading";
import styles from "./styles.module.css";
import Readme from "@site/docs/home.md";
import MDXContent from "@theme/MDXContent";
import Advanced from "@site/src/theme/advanced-markdown.js";

const FeatureList = [
  {
    title: "Github Workflows",
    Class: "github_logo_svg",
    Svg: require("@site/static/img/logo-github.svg").default,
    description: (
      <>
        Taking full advantage of Github Workflows to create releases as the
        dependencies become available using this project{" "}
        <a href="https://github.com/userdocs/qbt-workflow-files">
          qbt-workflow-files
        </a>
      </>
    ),
  },
  {
    title: "Alpine Linux and musl",
    Class: "alpine_logo_svg",
    Svg: require("@site/static/img/logo-alpine.svg").default,
    description: (
      <>
        Built by{" "}
        <a href="https://github.com/userdocs/qbt-musl-cross-make">
          musl cross build tools
        </a>{" "}
        and <a href="https://www.alpinelinux.org">Alpine Linux</a> we can easily
        create a glibc free fully static binary which is easy to deploy
      </>
    ),
  },
  {
    title: "qBittorrent-nox",
    Class: "qbittorrent_logo_svg",
    Svg: require("@site/static/img/logo-qbittorrent.svg").default,
    description: (
      <>
        Creating an always up to date and optimised qbittorrent-nox binary that
        will work on any linux based OS with a modern kernel, for 14
        architectures.
      </>
    ),
  },
];

function Feature({ Svg, title, description }) {
  return (
    <div className={clsx("col col--4")}>
      <div className="text--center">
        <Svg className={styles.featureSvg} role="img" />
      </div>
      <div className="text--center padding-horiz--md">
        <Heading as="h3">{title}</Heading>
        <p>{description}</p>
      </div>
    </div>
  );
}

export default function HomepageFeatures() {
  return (
    <section>
      <section className={styles.features}>
        <div className="container">
          <div className="row">
            {FeatureList.map((props, idx) => (
              <Feature key={idx} {...props} />
            ))}
          </div>
        </div>
      </section>
      <section>
        <Advanced>
          <div className="container myindex">
            <MDXContent>
              <Readme />
            </MDXContent>
          </div>
        </Advanced>
      </section>
    </section>
  );
}
