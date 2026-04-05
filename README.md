# qBittorrent-nox Static Builds

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/9817ad80d35c480aa9842b53001d55b0)](https://app.codacy.com/gh/userdocs/qbittorrent-nox-static?utm_source=github.com&utm_medium=referral&utm_content=userdocs/qbittorrent-nox-static&utm_campaign=Badge_Grade)
[![CodeFactor](https://www.codefactor.io/repository/github/userdocs/qbittorrent-nox-static/badge)](https://www.codefactor.io/repository/github/userdocs/qbittorrent-nox-static)
[![CI](https://github.com/userdocs/qbittorrent-nox-static/actions/workflows/ci-main-reusable-caller.yml/badge.svg)](https://github.com/userdocs/qbittorrent-nox-static/actions/workflows/ci-main-reusable-caller.yml)

Cross-platform static builds of qBittorrent-nox with the latest dependencies.

[Latest Release](https://github.com/userdocs/qbittorrent-nox-static/releases/latest) | [Documentation](https://userdocs.github.io/qbittorrent-nox-static/introduction/) | [All Releases](https://github.com/userdocs/qbittorrent-nox-static/tags)

> [!TIP]
> Docker: Use https://hotio.dev/containers/qbittorrent — Libtorrent `v1.2` and `v2` static builds combined into a single docker image with VPN support.

## Overview

A bash build script that compiles fully static `qbittorrent-nox` binaries using the latest source releases of all dependencies. Static binaries run on any Linux distribution with a matching CPU architecture — no external libraries required.

**Supported architectures:** `x86` `x86_64` `armhf` `armv7` `aarch64` `s390x` `powerpc` `ppc64el` `mips` `mipsel` `mips64` `mips64el` `riscv64` `loongarch64`

## Quick Install

> [!NOTE]
> The quick installer `qi.bash` supports Alpine and Debian-based systems.

```bash
# Latest release (libtorrent v2)
bash <(curl -sL usrdx.github.io/s/qi.bash)

# Latest release (libtorrent v1.2)
bash <(curl -sL usrdx.github.io/s/qi.bash) -lt v1

# Force a specific architecture
bash <(curl -sL usrdx.github.io/s/qi.bash) -lt v1 -fa armv7

# Show help
bash <(curl -sL usrdx.github.io/s/qi.bash) -h
```

> [!TIP]
> Access the WebUI at `http://localhost:8080`

## Manual Install

<details>
<summary>Download commands per architecture</summary>

**x86_64**

```bash
mkdir -p ~/bin && source ~/.profile
wget -qO ~/bin/qbittorrent-nox https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/x86_64-qbittorrent-nox
chmod 700 ~/bin/qbittorrent-nox
```

**aarch64**

```bash
mkdir -p ~/bin && source ~/.profile
wget -qO ~/bin/qbittorrent-nox https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/aarch64-qbittorrent-nox
chmod 700 ~/bin/qbittorrent-nox
```

**armv7**

```bash
mkdir -p ~/bin && source ~/.profile
wget -qO ~/bin/qbittorrent-nox https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/armv7-qbittorrent-nox
chmod 700 ~/bin/qbittorrent-nox
```

**armhf**

```bash
mkdir -p ~/bin && source ~/.profile
wget -qO ~/bin/qbittorrent-nox https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/armhf-qbittorrent-nox
chmod 700 ~/bin/qbittorrent-nox
```

**x86**

```bash
mkdir -p ~/bin && source ~/.profile
wget -qO ~/bin/qbittorrent-nox https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/x86-qbittorrent-nox
chmod 700 ~/bin/qbittorrent-nox
```

</details>

## Libtorrent Versions

Both Libtorrent v1.2 (stable) and v2.0 (latest features) builds are provided with every release.

> [!IMPORTANT]
> Libtorrent v1.2 is the main branch supported by qBittorrent since [4.4.5](https://www.qbittorrent.org/news#tuesday-aug-30th-2022---qbittorrent-v4.4.5-release).

## Version Management

Each release includes `dependency-version.json` with version metadata for all dependencies.

```bash
curl -sL https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/dependency-version.json
```

<details>
<summary>Example output</summary>

```json
{
    "openssl": "3.2.0",
    "boost": "1.84.0",
    "libtorrent_1_2": "1.2.19",
    "libtorrent_2_0": "2.0.9",
    "qt5": "5.15.12",
    "qt6": "6.6.1",
    "qbittorrent": "4.6.2",
    "revision": "3"
}
```

</details>

### Release Tags

Get the release tag for a specific libtorrent version:

```bash
# Libtorrent v1.2
jq -r '. | "release-\(.qbittorrent)_v\(.libtorrent_1_2)"' < <(curl -sL https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/dependency-version.json)

# Libtorrent v2.0
jq -r '. | "release-\(.qbittorrent)_v\(.libtorrent_2_0)"' < <(curl -sL https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/dependency-version.json)
```

### Build Revisions

Five dependencies trigger automatic rebuilds: qBittorrent, Libtorrent, Qt, Boost, and OpenSSL.

- Updates to qBittorrent or Libtorrent create **new releases** starting at revision `0`
- Updates to Qt, Boost, or OpenSSL update **existing release assets** and increment the revision

```bash
# Check latest revision
jq -r '.revision' < <(curl -sL "https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/dependency-version.json")
```

> [!IMPORTANT]
> Starting with qBittorrent v5, only CMake builds are supported with Qt6 as the default. Qt5 builds are considered legacy.

## Build Attestation

Binaries from `release-5.0.0_v2.0.10` / `release-5.0.0_v1.2.19` revision `1` onwards use [actions/attest-build-provenance](https://github.com/actions/attest-build-provenance) for cryptographic verification.

```bash
gh attestation verify x86_64-qbittorrent-nox -o userdocs
```

<details>
<summary>Example verification output</summary>

```
Loaded digest sha256:a656ff57b03ee6218205d858679ea189246caaecbbcc38d4d2b57eb81d8e59bb for file://x86_64-qbittorrent-nox
Loaded 1 attestation from GitHub API
✓ Verification succeeded!

sha256:a656ff57b03ee6218205d858679ea189246caaecbbcc38d4d2b57eb81d8e59bb was attested by:
REPO                             PREDICATE_TYPE                  WORKFLOW
userdocs/qbittorrent-nox-static  https://slsa.dev/provenance/v1  .github/workflows/matrix_multi_build_and_release_qbt_workflow_files.yml@refs/heads/master
```

</details>

## Related Projects

- [qbt-musl-cross-make](https://github.com/userdocs/qbt-musl-cross-make) — Cross-compilation toolchain
- [qbt-workflow-files](https://github.com/userdocs/qbt-workflow-files) — CI/CD workflow templates
- [qbt-host-deps](https://github.com/userdocs/qbt-host-deps) — Host dependency management

## Documentation

For build instructions, advanced configuration, and troubleshooting, visit the [project documentation](https://userdocs.github.io/qbittorrent-nox-static/introduction/).

> [!TIP]
> These static binaries work on WSL2 — access the WebUI at `localhost:8080` from your Windows browser.
