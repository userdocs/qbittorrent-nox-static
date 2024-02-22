import React from "react";
import clsx from "clsx";
import Link from "@docusaurus/Link";
import useDocusaurusContext from "@docusaurus/useDocusaurusContext";
import Layout from "@theme/Layout";
import HomepageFeatures from "@site/src/components/HomepageFeatures";
import Fml from "@site/static/img/userdocs-social-card.svg";
import styles from "./index.module.css";
import Advanced from "@site/src/theme/advanced-button.js";

function HomepageHeader() {
  const { siteConfig } = useDocusaurusContext();
  return (
    <header className={clsx("hero hero--primary", styles.heroBanner)}>
      <div className="container">
        <Fml className="social-card" />

        <div className={styles.buttons + " my-buttons"}>
          <Link
            className="button button--secondary button--lg my-buttons"
            to="/docs/introduction"
          >
            Documentation
          </Link>
          <Link
            className="button button--secondary button--lg my-buttons"
            to="https://github.com/userdocs/qbittorrent-nox-static/releases/latest"
          >
            Latest Release
          </Link>

          <Link
            className="button button--secondary button--lg my-buttons"
            to="https://github.com/userdocs/qbittorrent-nox-static-legacy/releases/latest"
          >
            Legacy Release
          </Link>

          <Link
            className="button button--secondary button--lg my-buttons"
            to="https://github.com/userdocs/qbt-workflow-files/releases/latest"
          >
            qbt-workflow-files
          </Link>
        </div>
      </div>
    </header>
  );
}

export default function Home() {
  const { siteConfig } = useDocusaurusContext();
  return (
    <Layout
      title={`${siteConfig.title}`}
      description="Documentation for the userdocs/qbittorrent-nox-static bash build script Github project"
    >
      <HomepageHeader />
      <main>
        <HomepageFeatures />
      </main>
    </Layout>
  );
}
