# qbittorrent-nox-static

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/9817ad80d35c480aa9842b53001d55b0)](https://app.codacy.com/gh/userdocs/qbittorrent-nox-static?utm_source=github.com&utm_medium=referral&utm_content=userdocs/qbittorrent-nox-static&utm_campaign=Badge_Grade)
[![CodeFactor](https://www.codefactor.io/repository/github/userdocs/qbittorrent-nox-static/badge)](https://www.codefactor.io/repository/github/userdocs/qbittorrent-nox-static)
[![CI](https://github.com/userdocs/qbittorrent-nox-static/actions/workflows/ci-main-reusable-caller.yml/badge.svg)](https://github.com/userdocs/qbittorrent-nox-static/actions/workflows/ci-main-reusable-caller.yml)

## Summary

The `qbittorrent-nox-static` project is a `bash` build script that compiles a static `qbittorrent-nox` binary using the latest available dependencies from their source. These statically linked binaries can run on any matching CPU architecture and are not OS specific. This means you can run a `x86_64` Alpine edge build on any Linux based OS of like CentOS | Fedora | OpenSuse | Debian | Ubuntu and more.

> [!TIP]
> You don't need to use the script to access the binaries it creates, just use the [release tag](https://github.com/userdocs/qbittorrent-nox-static/tags) you need or [latest release page](https://github.com/userdocs/qbittorrent-nox-static/releases/latest)

See here for how to [install the latest release](https://github.com/userdocs/qbittorrent-nox-static?tab=readme-ov-file#install-the-latest-release)

## Linked Github repositories

This build script uses and depends on some related repositories.

-   [qbt-musl-cross-make](https://github.com/userdocs/qbt-musl-cross-make)
-   [qbt-workflow-files](https://github.com/userdocs/qbt-workflow-files)
-   [qbt-ninja-build](https://github.com/userdocs/qbt-ninja-build)
-   [qbt-cmake-ninja-crossbuilds](https://github.com/userdocs/qbt-cmake-ninja-crossbuilds)

## Documentation

> [!TIP]
> Visit the [documentation](https://userdocs.github.io/qbittorrent-nox-static/introduction/) for in depth information on using this project and script usage.

## WSL2

> [!TIP]
> These static builds can be used on WSL2 and accessed via `localhost:8080` using the download instructions below

## Install the latest release

> [!TIP]
> For the most current build visit the [latest release page](https://github.com/userdocs/qbittorrent-nox-static/releases/latest)

Or uses these commands for your arch:

### x86

```bash
mkdir -p ~/bin && source ~/.profile
wget -qO ~/bin/qbittorrent-nox https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/x86-qbittorrent-nox
chmod 700 ~/bin/qbittorrent-nox
```

### x86_64

```bash
mkdir -p ~/bin && source ~/.profile
wget -qO ~/bin/qbittorrent-nox https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/x86_64-qbittorrent-nox
chmod 700 ~/bin/qbittorrent-nox
```

### armhf (armv6)

```bash
mkdir -p ~/bin && source ~/.profile
wget -qO ~/bin/qbittorrent-nox https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/armhf-qbittorrent-nox
chmod 700 ~/bin/qbittorrent-nox
```

### armv7

```bash
mkdir -p ~/bin && source ~/.profile
wget -qO ~/bin/qbittorrent-nox https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/armv7-qbittorrent-nox
chmod 700 ~/bin/qbittorrent-nox
```

### aarch64

```bash
mkdir -p ~/bin && source ~/.profile
wget -qO ~/bin/qbittorrent-nox https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/aarch64-qbittorrent-nox
chmod 700 ~/bin/qbittorrent-nox
```

## Libtorrent versions

> [!IMPORTANT]
> Libtorrent `v1.2` is currently the main branch supported by qBittorrent since a change with the release of [4.4.5](https://www.qbittorrent.org/news.php)

Libtorrent `v2.0` builds are still released as latest releases as it it does not really matter to this project as it always builds and releases for both `v1.2` and `v2.0`. See the next section for how to get the version you need via the latest release URL.

> [!TIP]
> You can view the current latest and pre releases and tags here <https://github.com/userdocs/qbittorrent-nox-static/tags>

## Getting the Version you want via the latest release URL

Since this project builds and releases both v1.2 and v2.0 builds simultaneously we can use the commands below to always get the latest version of the related pre release via the latest release `dependency-version.json` asset.

Using this method it does not matter which version is the latest release or pre release as the commands will provide you the version specific info you need for the twinned latest/pre releases.

For Libtorrent `v1.2`

```bash
jq -r '. | "release-\(.qbittorrent)_v\(.libtorrent_1_2)"' < <(curl -sL https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/dependency-version.json)
```

For Libtorrent `v2.0`

```bash
jq -r '. | "release-\(.qbittorrent)_v\(.libtorrent_2_0)"' < <(curl -sL https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/dependency-version.json)
```

## Revisions

The build has 5 main dependencies tracked that will trigger a rebuild on an update being available.

-   qBittorrent
-   Libtorrent
-   Qt
-   Boost
-   Openssl

When a new build is triggered for updating `qBittorrent` or `Libtorrent` a new release will be generated as the release tags will be updated.

Since I do not append revision info to tags `Qt` - `Boost` - `Openssl` or patched builds it will only update the existing release assets.

Revisions values are incremented in the `dependency-version.json` of the release. All new releases start at a revision of `0` and increment by `1` per revised build.

### Tracking latest release revisions (Libtorrent v2.0)

Simply use this command.

```bash
jq -r '.revision' < <(curl -sL "https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/dependency-version.json")
```

### Tracking v2.0 and v1.2 releases independently

There are times when the revision counts may differ between `v2.0` and `v1.2` builds as the `dependency-version.json` is unique to the release but has some shared values that won't change. In this case you need to track them as independent values unique to their release.

To do this you start by getting the current release version value first, for example, getting the `v1.2` prerelease revision value.

```bash
release="$(jq -r '. | "release-\(.qbittorrent)_v\(.libtorrent_1_2)"' < <(curl -sL https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/dependency-version.json))"
```

Then get the revision from that specific release.

```bash
jq -r '.revision' < <(curl -sL "https://github.com/userdocs/qbittorrent-nox-static/releases/download/${release}/dependency-version.json")
```

Now you have tracked the current revision of the latest release of the libtorrent v1.2 binary.

## Dependency json

From `release-4.4.5` each release contains a `dependency-version.json` file that provide some key version information for that is shared across the latest release and the twinned pre release. This helps to overcome some limitations of the API for consistently and directly accessing this information.

Downloading the file like this:

```bash
curl -sL https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/dependency-version.json
```

Will output a result like this:

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

As demonstrated above by using the latest release URL we can construct the tag of the twinned pre release and therefore the asset URL with no margin for error.

> [!IMPORTANT]
> From the release of qBittorrent v5 configure based builds will be unsupported and we will only be able to use cmake to build qBittorrent v5 onwards. All releases from that point on will drop Qt5 builds as at this point cmake,Qt6 and v5 should be the default and preferred build combination with Qt5 being a legacy dependency.

## gh attestation verify

Binaries built from the release of release `release-5.0.0_v2.0.10` and `release-5.0.0_v1.2.19` revision `1` use [actions/attest-build-provenance](https://github.com/actions/attest-build-provenance)

Verify the integrity and provenance of an artifact using its associated cryptographically signed attestations.

https://cli.github.com/manual/gh_attestation_verify

For example:

```bash
gh attestation verify x86_64-qbittorrent-nox -o userdocs
```

Will give you this result for the `release-5.0.0_v2.0.10` revision `1` binary.

```bash
Loaded digest sha256:a656ff57b03ee6218205d858679ea189246caaecbbcc38d4d2b57eb81d8e59bb for file://x86_64-qbittorrent-nox
Loaded 1 attestation from GitHub API
✓ Verification succeeded!

sha256:a656ff57b03ee6218205d858679ea189246caaecbbcc38d4d2b57eb81d8e59bb was attested by:
REPO                             PREDICATE_TYPE                  WORKFLOW
userdocs/qbittorrent-nox-static  https://slsa.dev/provenance/v1  .github/workflows/matrix_multi_build_and_release_qbt_workflow_files.yml@refs/heads/master
```
