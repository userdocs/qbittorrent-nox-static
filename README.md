# qbittorrent-nox-static

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/9817ad80d35c480aa9842b53001d55b0)](https://app.codacy.com/gh/userdocs/qbittorrent-nox-static?utm_source=github.com&utm_medium=referral&utm_content=userdocs/qbittorrent-nox-static&utm_campaign=Badge_Grade)
[![CodeFactor](https://www.codefactor.io/repository/github/userdocs/qbittorrent-nox-static/badge)](https://www.codefactor.io/repository/github/userdocs/qbittorrent-nox-static)
[![matrix multi build and release](https://github.com/userdocs/qbittorrent-nox-static/actions/workflows/matrix_multi_build_and_release_qbt_workflow_files.yml/badge.svg)](https://github.com/userdocs/qbittorrent-nox-static/actions/workflows/matrix_multi_build_and_release.yml)
[![Debian Based CI](https://github.com/userdocs/qbittorrent-nox-static/actions/workflows/debian_based_CI.yml/badge.svg)](https://github.com/userdocs/qbittorrent-nox-static/actions/workflows/debian_based_CI.yml)

## Linked Github repositories

This build script uses and depends on some related repositories

- [qbt-musl-cross-make](https://github.com/userdocs/qbt-musl-cross-make)

  `qbt-musl-cross-make` builds the customised [musl cross make toolchains](https://git.zv.io/toolchains/musl-cross-make) this build script uses for Alpine based builds.

- [qbt-workflow-files](https://github.com/userdocs/qbt-workflow-files)

  This is a dependency tracker that checks for and releases all of the dependencies this build script needs as a [latest release](https://github.com/userdocs/qbt-workflow-files/releases/latest)

- [qbt-cmake-ninja-crossbuilds](https://github.com/userdocs/qbt-cmake-ninja-crossbuilds)

  This is a packaged release of cmake and ninja build for crossbuilds on debian based systems.

## Summary

The `qbittorrent-nox-static` project is a `bash` build script that compiles a static `qbittorrent-nox` binary using the latest available dependencies from their source. These statically linked binaries can run on any matching CPU architecture and are not OS specific. This means you can run a `x86_64` Alpine edge build on any Linux based OS of like CentOS | Fedora | OpenSuse | Debian Stretch | Ubuntu Xenial and more.

## Documentation

🔵 [Visit the documentation](https://userdocs.github.io/qbittorrent-nox-static/#/README) for in depth information on using this project.

## WSL2

🟢 These static builds can be used on WSL2 and accessed via `localhost:8080` using the download instructions below

## Install the latest release

🔵 [The latest release page](https://github.com/userdocs/qbittorrent-nox-static/releases/latest) for the most current build

Or uses these commands for your arch:

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

## Non ICU builds - depreciated from `release-4.4.3.1_v2.0.6`

Each build has two versions due to how `qtbase` builds when it detects `ICU` .

🟢 The `iconv`  / non `ICU` build can be considered the default build.

ICU replaces `iconv` if detected when `qtbase` is built and doubles the static build size due to the ICU libraries being linked into the final static binary.

🔵 When not using `ICU` everything is built against `iconv`

🟠 `ICU` builds have nothing to do with performance.

The reason I do two builds is that `ICU` is an automated build flag preference for `QT` (and boost when I was building that) and I considered that it may one day be a default or only option and `ICU` seems to be the preferred choice for this kind of library. So it's really not a critical option but more of a choice.

🔵 `ICU` is a preferred build path automatically chosen by the programs built if it is present on the system.

You can pick either version you want, if it works then just enjoy it. The only difference you may experience is how the WebUi displays Unicode characters.

## Libtorrent v1.2 builds

🟠 Libtorrent v1.2 is currently the main branch supported by qBittorrent [since 4.4.5](https://www.qbittorrent.org/news.php)

Libtorrent v2.0 builds are still released as latest releases. You can view the pre releases and tags here.

## Getting the Version you want via the latest release

Since this project builds and release both v1.2 and v2.0 builds simultaneously we can use the commands below to always get the latest version of the related pre release via the latest release `dependency-version.json` asset.

Use this method to target the pre release linked to a latest release.

```bash
jq -r '. | "release-\(.qbittorrent)_v\(.libtorrent_1_2)"' < <(curl -sL https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/dependency-version.json)
jq -r '. | "release-\(.qbittorrent)_v\(.libtorrent_2_0)"' < <(curl -sL https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/dependency-version.json)
```

## Revisions

The build have 5 main dependencies that will trigger a rebuild on an update.

- qBittorrent
- Libtorrent
- Qt base/tools
- Boost
- Openssl

When a new build is triggered for updating qBittorrent or Libtorrent a new release will be generated as the release tags will be updated

Since I do not append revision info to tags Qt/Boost/Openssl builds will update the existing release assets.

To track these revisions you can use this command. All new releases start at a revision of `0` and increment by `1` per revised build.

```bash
jq -r '.revision' < <(curl -sL "https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/dependency-version.json")
```

🔵 <https://github.com/userdocs/qbittorrent-nox-static/releases>

## Build table - Dependencies - arch - OS - build tools

|       Deps        | x86_64 | aarch64 | armv7 | armhf (v6) | Debian based | Alpine | make  | cmake |  b2   | qmake |
| :---------------: | :----: | :-----: | :---: | :--------: | :----------: | :----: | :---: | :---: | :---: | :---: |
|       bison       |   ✅    |    ✅    |   ✅   |     ✅      |      ✅       |   ❌    |   ✅   |   ❌   |   ❌   |   ❌   |
|       gawk        |   ✅    |    ✅    |   ✅   |     ✅      |      ✅       |   ❌    |   ✅   |   ❌   |   ❌   |   ❌   |
|       glibc       |   ✅    |    ✅    |   ✅   |     ✅      |      ✅       |   ❌    |   ✅   |   ❌   |   ❌   |   ❌   |
|       zlib        |   ✅    |    ✅    |   ✅   |     ✅      |      ✅       |   ✅    |   ✅   |   ❌   |   ❌   |   ❌   |
|       iconv       |   ✅    |    ✅    |   ✅   |     ✅      |      ✅       |   ✅    |   ✅   |   ❌   |   ❌   |   ❌   |
|        icu        |   ✅    |    ✅    |   ✅   |     ✅      |      ✅       |   ✅    |   ✅   |   ❌   |   ❌   |   ❌   |
|      openssl      |   ✅    |    ✅    |   ✅   |     ✅      |      ✅       |   ✅    |   ✅   |   ❌   |   ❌   |   ❌   |
|       boost       |   ✅    |    ✅    |   ✅   |     ✅      |      ✅       |   ✅    |   ✅   |   ❌   |   ✅   |   ❌   |
|    libtorrent     |   ✅    |    ✅    |   ✅   |     ✅      |      ✅       |   ✅    |   ✅   |   ✅   |   ✅   |   ❌   |
|      qt5base      |   ✅    |    ✅    |   ✅   |     ✅      |      ✅       |   ✅    |   ❌   |   ❌   |   ❌   |   ✅   |
|      qt5tools     |   ✅    |    ✅    |   ✅   |     ✅      |      ✅       |   ✅    |   ❌   |   ❌   |   ❌   |   ✅   |
| double conversion |   ✅    |    ✅    |   ✅   |     ✅      |      ✅       |   ✅    |   ❌   |   ✅   |   ❌   |   ❌   |
|      qt6base      |   ✅    |    ✅    |   ✅   |     ✅      |      ✅       |   ✅    |   ❌   |   ✅   |   ❌   |   ❌   |
|      qt6tools     |   ✅    |    ✅    |   ✅   |     ✅      |      ✅       |   ✅    |   ❌   |   ✅   |   ❌   |   ❌   |
|    qbittorrent    |   ✅    |    ✅    |   ✅   |     ✅      |      ✅       |   ✅    |   ❌   |   ✅   |   ❌   |   ✅   |
