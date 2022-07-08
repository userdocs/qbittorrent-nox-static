# qbittorrent-nox-static

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/9817ad80d35c480aa9842b53001d55b0)](https://app.codacy.com/gh/userdocs/qbittorrent-nox-static?utm_source=github.com&utm_medium=referral&utm_content=userdocs/qbittorrent-nox-static&utm_campaign=Badge_Grade)
[![CodeFactor](https://www.codefactor.io/repository/github/userdocs/qbittorrent-nox-static/badge)](https://www.codefactor.io/repository/github/userdocs/qbittorrent-nox-static)
[![matrix multi build and release](https://github.com/userdocs/qbittorrent-nox-static/actions/workflows/matrix_multi_build_and_release_qbt_workflow_files.yml/badge.svg)](https://github.com/userdocs/qbittorrent-nox-static/actions/workflows/matrix_multi_build_and_release.yml)
[![Debian Based CI](https://github.com/userdocs/qbittorrent-nox-static/actions/workflows/debian_based_CI.yml/badge.svg)](https://github.com/userdocs/qbittorrent-nox-static/actions/workflows/debian_based_CI.yml)

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

## ICU builds

Each build has two versions due to how `qtbase` builds when it detects `ICU` .

🟢 The `iconv`  / non `ICU` build can be considered the default build.

ICU replaces `iconv` if detected when `qtbase` is built and doubles the static build size due to the ICU libraries being linked into the final static binary.

🔵 When not using `ICU` everything is built against `iconv`

🟠 `ICU` builds have nothing to do with performance.

The reason I do two builds is that `ICU` is an automated build flag preference for `QT` (and boost when I was building that) and I considered that it may one day be a default or only option and `ICU` seems to be the preferred choice for this kind of library. So it's really not a critical option but more of a choice.

🔵 `ICU` is a preferred build path automatically chosen by the programs built if it is present on the system.

You can pick either version you want, if it works then just enjoy it. The only difference you may experience is how the WebUi displays Unicode characters.

## Libtorrent v1.2 builds

🟠 Libtorrent v2.0 is currently the main branch supported by qBittorrent

Libtorrent v1.2 builds are released as pre releases. You can view the pre releases and tags here.

🔵 https://github.com/userdocs/qbittorrent-nox-static/releases

## Build table - Dependencies - arch - OS - build tools

|       Deps        | x86_64 | aarch64 | armv7 | armhf (v6) | Debian based | Alpine | make  | cmake |  b2   | qmake |
| :---------------: | :----: | :-----: | :---: | :--------: | :----------: | :----: | :---: | :---: | :---: | :---: |
|    libexecinfo    |   ✅    |    ✅    |   ✅   |     ✅      |      ❌       |   ✅    |   ❌   |   ❌   |   ❌   |   ❌   |
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
|      qt5ools      |   ✅    |    ✅    |   ✅   |     ✅      |      ✅       |   ✅    |   ❌   |   ❌   |   ❌   |   ✅   |
| double conversion |   ✅    |    ✅    |   ✅   |     ✅      |      ✅       |   ✅    |   ❌   |   ✅   |   ❌   |   ❌   |
|      qt6base      |   ✅    |    ✅    |   ✅   |     ✅      |      ✅       |   ✅    |   ❌   |   ✅   |   ❌   |   ❌   |
|      qt6ools      |   ✅    |    ✅    |   ✅   |     ✅      |      ✅       |   ✅    |   ❌   |   ✅   |   ❌   |   ❌   |
|    qbittorrent    |   ✅    |    ✅    |   ✅   |     ✅      |      ✅       |   ✅    |   ❌   |   ✅   |   ❌   |   ✅   |
