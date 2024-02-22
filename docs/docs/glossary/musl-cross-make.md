---
title: Musl Cross Make
---

Custom musl crossbuild toolchains based on musl.cc

---

The main musl cross make is located here https://github.com/richfelker/musl-cross-make and the tools used here are derived from this.

[musl.cc](https://musl.cc) is a fork of the original mcm (musl cross make) project and they release and host cross toolchains to be used. The repo for the project is found here [https://git.zv.io/toolchains/musl-cross-make/-/tree/master](https://git.zv.io/toolchains/musl-cross-make/-/tree/master)

This project uses a modified version of the [musl.cc](https://musl.cc) musl cross make tool build tools.

It uses newer dependencies, is smaller in size and stays in sync with Alpine target architectures profiles.

They can be found here https://github.com/userdocs/qbt-musl-cross-make

These are the tool chains used by this project to build static binaries on the Alpine Host, which is the default setup for the github releases.
