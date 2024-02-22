---
title: Qemu emulation
---

Qemu is a generic and open source machine emulator and virtualizer

It's used when cross building so that created binaries and libs can be automatically loaded and used without host arch versions.

---

We use [qemu-user-static](https://packages.ubuntu.com/lunar/qemu-user-static) and [binfmt-support](https://packages.ubuntu.com/lunar/binfmt-support) on the Github `ubuntu-latest` runners, from the [Lunar](https://releases.ubuntu.com/lunar) repo to overcome a bug in older versions.

For example, when cross compiling Qt6 you they want you to have a have a host version built first and then use loads of special cmake settings.

The few binaries that are actually needed are not part of the final build so they are emulated as and when needed and it works fine.

So by having emulation at hand when needed we can easily handle certain cross compilation issues easily.

Qt5 does not need to do this as `qmake` build the tools for the host first. Apparently it's a cmake limitation.
