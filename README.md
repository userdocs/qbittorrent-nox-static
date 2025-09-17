# qBittorrent-nox Static Builds

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/9817ad80d35c480aa9842b53001d55b0)](https://app.codacy.com/gh/userdocs/qbittorrent-nox-static?utm_source=github.com&utm_medium=referral&utm_content=userdocs/qbittorrent-nox-static&utm_campaign=Badge_Grade)
[![CodeFactor](https://www.codefactor.io/repository/github/userdocs/qbittorrent-nox-static/badge)](https://www.codefactor.io/repository/github/userdocs/qbittorrent-nox-static)
[![CI](https://github.com/userdocs/qbittorrent-nox-static/actions/workflows/ci-main-reusable-caller.yml/badge.svg)](https://github.com/userdocs/qbittorrent-nox-static/actions/workflows/ci-main-reusable-caller.yml)

Cross-platform static builds of qBittorrent-nox with the latest dependencies

[📦 Latest Release](https://github.com/userdocs/qbittorrent-nox-static/releases/latest) • [📖 Documentation](https://userdocs.github.io/qbittorrent-nox-static/introduction/) • [🏷️ All Releases](https://github.com/userdocs/qbittorrent-nox-static/tags)

> [!TIP]
>
> Docker: Use https://hotio.dev/containers/qbittorrent
>
> Libtorrent `v1.2` and `v2` static builds combined into a single docker image with vpn support.

## 🚀 Quick Start

### Quick Install

> [!NOTE]
>
> `qi.bash`: The quick installer supports Alpine or Debian like systems.

Latest release using libtorrent `v2`

```bash
bash <(curl -sL usrdx.github.io/s/qi.bash)
```

Latest release using libtorrent `v1.2`

```bash
bash <(curl -sL usrdx.github.io/s/qi.bash) -lt v1
```

Using Libtorrent v1.2 and forcing the armv7 binary

```bash
bash <(curl -sL usrdx.github.io/s/qi.bash) -lt v1 -fa armv7
```

Show the help section

```bash
bash <(curl -sL usrdx.github.io/s/qi.bash) -h
```

You can now run it using this command:

```bash
~/bin/qbittorrent
```

> [!TIP]
> Access the WebUI at `http://localhost:8080`

### What You Get

- ✅ **No installation hassles** - Single static binary
- ✅ **Latest versions** - Always up-to-date dependencies
- ✅ **Universal compatibility** - Runs on any Linux distro
- ✅ **Multiple architectures** - Support for ARM devices too

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Installation](#-installation)
- [Libtorrent Versions](#-libtorrent-versions)
- [Version Management](#-version-management)
- [Dependency Tracking](#-dependency-tracking)
- [Build Attestation](#%EF%B8%8F-build-attestation)
- [Related Projects](#-related-projects)
- [WSL2 Support](#-wsl2-support)
- [Documentation](#-documentation)

## 🔍 Overview

The `qbittorrent-nox-static` project provides a bash build script that compiles static `qbittorrent-nox` binaries using the latest available dependencies from their source. These statically linked binaries offer several advantages:

- **Universal compatibility**: Run on any Linux distribution with matching CPU architecture
- **No dependencies**: All required libraries are statically linked
- **Latest versions**: Built with the most recent stable releases of all dependencies
- **Multiple architectures**: Support for x86, x86_64, ARM variants

## ✨ Features

- 🔧 **Static compilation** - No external dependencies required
- 🏗️ **Multi-architecture support** - x86, x86_64, armhf, armv7, aarch64
- 📦 **Latest dependencies** - Always built with current stable versions
- 🔄 **Automated builds** - CI/CD pipeline ensures fresh releases
- 🛡️ **Build attestation** - Cryptographically signed provenance
- 📊 **Version tracking** - JSON metadata for dependency versions

## 📦 Installation

Choose the command that matches your system architecture:

### x86 (32-bit Intel/AMD)

```bash
mkdir -p ~/bin && source ~/.profile
wget -qO ~/bin/qbittorrent-nox https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/x86-qbittorrent-nox
chmod 700 ~/bin/qbittorrent-nox
```

### x86_64 (64-bit Intel/AMD)

```bash
mkdir -p ~/bin && source ~/.profile
wget -qO ~/bin/qbittorrent-nox https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/x86_64-qbittorrent-nox
chmod 700 ~/bin/qbittorrent-nox
```

### armhf (ARM v6 - Raspberry Pi 1/Zero)

```bash
mkdir -p ~/bin && source ~/.profile
wget -qO ~/bin/qbittorrent-nox https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/armhf-qbittorrent-nox
chmod 700 ~/bin/qbittorrent-nox
```

### armv7 (ARM v7 - Raspberry Pi 2/3/4 32-bit)

```bash
mkdir -p ~/bin && source ~/.profile
wget -qO ~/bin/qbittorrent-nox https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/armv7-qbittorrent-nox
chmod 700 ~/bin/qbittorrent-nox
```

### aarch64 (ARM 64-bit - Raspberry Pi 3/4/5 64-bit)

```bash
mkdir -p ~/bin && source ~/.profile
wget -qO ~/bin/qbittorrent-nox https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/aarch64-qbittorrent-nox
chmod 700 ~/bin/qbittorrent-nox
```

## 🔧 Libtorrent Versions

> [!IMPORTANT]
> **Libtorrent v1.2** is currently the main branch supported by qBittorrent since the release of [4.4.5](https://www.qbittorrent.org/news.php). However, both v1.2 and v2.0 builds are provided.

This project automatically builds and releases binaries for both Libtorrent versions:

- **Libtorrent v1.2**: Stable and widely supported (recommended)
- **Libtorrent v2.0**: Latest features and improvements

> [!TIP]
> You can view all current releases and pre-releases at <https://github.com/userdocs/qbittorrent-nox-static/tags>

## 🎯 Version Management

### Getting Version-Specific Releases

Since this project builds both v1.2 and v2.0 simultaneously, you can target specific libtorrent versions using these commands:

#### Libtorrent v1.2 Release Info

```bash
jq -r '. | "release-\(.qbittorrent)_v\(.libtorrent_1_2)"' < <(curl -sL https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/dependency-version.json)
```

#### Libtorrent v2.0 Release Info

```bash
jq -r '. | "release-\(.qbittorrent)_v\(.libtorrent_2_0)"' < <(curl -sL https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/dependency-version.json)
```

### Build Revisions

The build system tracks 5 main dependencies that trigger automatic rebuilds:

- qBittorrent
- Libtorrent
- Qt
- Boost
- OpenSSL

**Revision Tracking:**

- New releases start at revision `0`
- Incremented by `1` for each rebuild
- Updates to Qt, Boost, or OpenSSL only update existing release assets
- Updates to qBittorrent or Libtorrent create new releases

#### Check Latest Revision

```bash
jq -r '.revision' < <(curl -sL "https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/dependency-version.json")
```

#### Track Specific Version Revisions

For independent tracking of v1.2 and v2.0 revisions:

1. **Get the release tag:**

   ```bash
   release="$(jq -r '. | "release-\(.qbittorrent)_v\(.libtorrent_1_2)"' < <(curl -sL https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/dependency-version.json))"
   ```

2. **Get the revision for that release:**

   ```bash
   jq -r '.revision' < <(curl -sL "https://github.com/userdocs/qbittorrent-nox-static/releases/download/${release}/dependency-version.json")
   ```

## 📊 Dependency Tracking

Each release includes a `dependency-version.json` file that provides version information shared across latest and pre-releases. This helps overcome API limitations for consistent access to version data.

### Download Dependency Information

```bash
curl -sL https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/dependency-version.json
```

### Example Output

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

> [!IMPORTANT]
> Starting with qBittorrent v5, configure-based builds will be unsupported. Only CMake builds will be available, with Qt6 as the default. Qt5 builds will be considered legacy and eventually dropped.

## 🛡️ Build Attestation

Binaries built from `release-5.0.0_v2.0.10` and `release-5.0.0_v1.2.19` revision `1` onwards use [actions/attest-build-provenance](https://github.com/actions/attest-build-provenance) for cryptographic verification.

### Verify Binary Integrity

You can verify the integrity and provenance of downloaded binaries using GitHub CLI:

```bash
gh attestation verify x86_64-qbittorrent-nox -o userdocs
```

### Example Verification Output

```bash
Loaded digest sha256:a656ff57b03ee6218205d858679ea189246caaecbbcc38d4d2b57eb81d8e59bb for file://x86_64-qbittorrent-nox
Loaded 1 attestation from GitHub API
✓ Verification succeeded!

sha256:a656ff57b03ee6218205d858679ea189246caaecbbcc38d4d2b57eb81d8e59bb was attested by:
REPO                             PREDICATE_TYPE                  WORKFLOW
userdocs/qbittorrent-nox-static  https://slsa.dev/provenance/v1  .github/workflows/matrix_multi_build_and_release_qbt_workflow_files.yml@refs/heads/master
```

For more information, visit the [GitHub CLI attestation documentation](https://cli.github.com/manual/gh_attestation_verify).

## 🔗 Related Projects

This build script depends on several related repositories:

- [qbt-musl-cross-make](https://github.com/userdocs/qbt-musl-cross-make) - Cross-compilation toolchain
- [qbt-workflow-files](https://github.com/userdocs/qbt-workflow-files) - CI/CD workflow templates
- [qbt-host-deps](https://github.com/userdocs/qbt-host-deps) - Host dependency management

## 💻 WSL2 Support

> [!TIP]
> These static builds work perfectly on WSL2! After installation, access the WebUI at `localhost:8080` from your Windows browser.

The static nature of these builds makes them ideal for WSL2 environments where dependency management can be challenging.

## 📖 Documentation

> [!TIP]
> For comprehensive documentation, visit the [project documentation](https://userdocs.github.io/qbittorrent-nox-static/introduction/) which covers:
>
> - Detailed build instructions
> - Advanced configuration options
> - Troubleshooting guides
> - Contributing guidelines
