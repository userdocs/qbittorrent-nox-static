---
title: Musl Cross Make
hide_title: true
---

🟦 Custom musl crossbuild toolchains based on [musl-cross-make](https://github.com/richfelker/musl-cross-make)

---

The main musl cross make is located here https://github.com/richfelker/musl-cross-make and the tools used here are derived from this.

[musl.cc](https://musl.cc) is a fork of the original mcm (musl cross make) project and they release and host cross toolchains to be used. The repo for the project is found here [https://git.zv.io/toolchains/musl-cross-make/-/tree/master](https://git.zv.io/toolchains/musl-cross-make/-/tree/master)

This project uses a hybrid version of the [musl.cc](https://musl.cc) musl cross make tool build tools and [musl.cc](https://github.com/richfelker/musl-cross-make) hosted on Github.

It uses newer current dependencies, is smaller in size and stays in sync with Alpine target architecture profiles.

The build process is automated via Github Actions. They can be found here https://github.com/userdocs/qbt-musl-cross-make

:::note
These are the tool chains used by this project to build static binaries on the Alpine Host, which is the default setup for the github releases.
:::
