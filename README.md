# qbittorrent-nox-static

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/9817ad80d35c480aa9842b53001d55b0)](https://app.codacy.com/gh/userdocs/qbittorrent-nox-static?utm_source=github.com&utm_medium=referral&utm_content=userdocs/qbittorrent-nox-static&utm_campaign=Badge_Grade)
[![CodeFactor](https://www.codefactor.io/repository/github/userdocs/qbittorrent-nox-static/badge)](https://www.codefactor.io/repository/github/userdocs/qbittorrent-nox-static)
[![matrix multi build and release](https://github.com/userdocs/qbittorrent-nox-static/actions/workflows/matrix_multi_build_and_release.yml/badge.svg)](https://github.com/userdocs/qbittorrent-nox-static/actions/workflows/matrix_multi_build_and_release.yml)
[![Debian Based CI](https://github.com/userdocs/qbittorrent-nox-static/actions/workflows/debian_based_CI.yml/badge.svg)](https://github.com/userdocs/qbittorrent-nox-static/actions/workflows/debian_based_CI.yml)

## Summary

The [qbittorrent-nox-static](https://github.com/userdocs/qbittorrent-nox-static) project is a `bash` build script that compiles a static `qbittorrent-nox` binary using the latest available dependencies from their source. These statically linked binaries can run on any matching CPU architecture and are not OS specific. This means you can run a `x86_64` Alpine 3.13 build on Linux based of like CentOS | Fedora | OpenSuse | Debian Stretch | Ubuntu Xenial and more.

## Documentation

[Visit the documentation](https://userdocs.github.io/qbittorrent-nox-static/#/README)
## WSL2

These static builds can be used on WSL2 and accessed via `localhost:8080` using the download instructions

## Install the latest release

https://github.com/userdocs/qbittorrent-nox-static/releases/latest

## Libtorrent v2 builds

These are released as pre releases until qBittorrent officially adopts libtorrent v2 as the default version. You can the preview release and tags here.

https://github.com/userdocs/qbittorrent-nox-static/releases
### x86_64

```bash
mkdir -p ~/bin && source ~/.profile
wget -qO ~/bin/qbittorrent-nox https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/x86_64-icu-qbittorrent-nox
chmod 700 ~/bin/qbittorrent-nox
```

### armhf (armv6)

```bash
mkdir -p ~/bin && source ~/.profile
wget -qO ~/bin/qbittorrent-nox https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/armhf-icu-qbittorrent-nox
chmod 700 ~/bin/qbittorrent-nox
```

### armv7

```bash
mkdir -p ~/bin && source ~/.profile
wget -qO ~/bin/qbittorrent-nox https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/armv7-icu-qbittorrent-nox
chmod 700 ~/bin/qbittorrent-nox
```

### aarch64

```bash
mkdir -p ~/bin && source ~/.profile
wget -qO ~/bin/qbittorrent-nox https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/aarch64-icu-qbittorrent-nox
chmod 700 ~/bin/qbittorrent-nox
```

## Cmake builds

Cmake builds where libtorrent and qbittorrent are compiled using cmake and ninja are available

⚠️ Cmake builds do not get stripped (debug symbols). Use cmake builds for stacktrace / debugging features built into qbittorrent.

## Libtorrent v2 + QT6 + Qbittorrent using cmake

The script is ready to build using cmake and is QT6 ready. As soon as qbittorrrent has official support this script can build it.

## Build table - Dependencies - arch - OS - build tools

|    Deps     | x86_64 | aarch64 | Debian based | Alpine | make  | cmake |  b2   | qmake |
| :---------: | :----: | :-----: | :----------: | :----: | :---: | :---: | :---: | :---: |
| libexecinfo |   ✅    |    ✅    |      ❌       |   ✅    |   ❌   |   ❌   |   ❌   |   ❌   |
|    bison    |   ✅    |    ❌    |      ✅       |   ❌    |   ✅   |   ❌   |   ❌   |   ❌   |
|    gawk     |   ✅    |    ❌    |      ✅       |   ❌    |   ✅   |   ❌   |   ❌   |   ❌   |
|    glibc    |   ✅    |    ❌    |      ✅       |   ❌    |   ✅   |   ❌   |   ❌   |   ❌   |
|    zlib     |   ✅    |    ✅    |      ✅       |   ✅    |   ✅   |   ❌   |   ❌   |   ❌   |
|    iconv    |   ✅    |    ✅    |      ✅       |   ✅    |   ✅   |   ❌   |   ❌   |   ❌   |
|     icu     |   ✅    |    ✅    |      ✅       |   ✅    |   ✅   |   ❌   |   ❌   |   ❌   |
|   openssl   |   ✅    |    ✅    |      ✅       |   ✅    |   ✅   |   ❌   |   ❌   |   ❌   |
|    boost    |   ✅    |    ✅    |      ✅       |   ✅    |   ✅   |   ❌   |   ✅   |   ❌   |
| libtorrent  |   ✅    |    ✅    |      ✅       |   ✅    |   ✅   |   ✅   |   ✅   |   ❌   |
|   qt5base   |   ✅    |    ✅    |      ✅       |   ✅    |   ❌   |   ❌   |   ❌   |   ✅   |
|   qt5ools   |   ✅    |    ✅    |      ✅       |   ✅    |   ❌   |   ❌   |   ❌   |   ✅   |
|   qt6base   |   ✅    |    ✅    |      ✅       |   ✅    |   ❌   |   ✅   |   ❌   |   ❌   |
|   qt6ools   |   ✅    |    ✅    |      ✅       |   ✅    |   ❌   |   ✅   |   ❌   |   ❌   |
| qbittorrent |   ✅    |    ✅    |      ✅       |   ✅    |   ❌   |   ✅   |   ❌   |   ✅   |
