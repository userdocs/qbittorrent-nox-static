---
title: Musl Cross Make
hide_title: true
---

🟦 Custom musl cross build toolchains based on [musl-cross-make](https://github.com/richfelker/musl-cross-make)

---

The main musl cross make is located here https://github.com/richfelker/musl-cross-make and the tools used here are derived from this.

This project uses [qbt-musl-cross-make](https://github.com/userdocs/qbt-musl-cross-make)

Summary:

- It uses current build dependencies of `gcc` and `binutils`,
- It is optimized by build flags for toolchain and target
- focused on only `cc` and `c++` making for smaller toolchains
- Stays in sync with upstream Alpine target architecture profiles.
- Builds `static-pie` binaries.
- Provides prebuilt releases and docker images

The build process is fully automated via [Github Actions](https://github.com/userdocs/qbt-musl-cross-make/actions/workflows/ci-main-reusable-caller.yml).

Release and docker images can be found here:

Releases: https://github.com/userdocs/qbt-musl-cross-make/releases

Docker images: https://github.com/userdocs/qbt-musl-cross-make/pkgs/container/qbt-musl-cross-make

:::note
These are the tool chains used by this project to build static binaries on the Alpine Host, which is the default setup for the github releases.
:::
