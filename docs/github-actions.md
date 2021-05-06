There are some actions created that will build the binary and create and artifact. They can be viewed here

<https://github.com/userdocs/qbittorrent-nox-static/actions>

All these action are triggered manually by clicking on the action running the workflow.

You can fork the repo and build it yourself.

Patching will work with actions as long as you configure it correctly.

These the currently available actions.

**Note:** `qbittorrent-nox multi build` also generates a release based on the qbittorrent and libtorrent tags used. The release is created when the first matric build completes and the other builds update this release as they compelte.

```bash
qb-amd64 (on alpine - fast)
qb-amd64-patch (on alpine - fast)
qb-amd64-icu (on alpine - fast)
qb-amd64-icu-patch (on alpine - fast)

qb-arm64 (on alpine + qemu static emulation - slow)
qb-arm64-patch (on qemu static emulation - slow)
qb-arm64-icu (on qemu static emulation - slow)
qb-arm64-icu-patch (on qemu static emulation - slow)

qbittorrent-nox multi build (x86_64 and aarch64 + release with aarch64 cross built via musl prebuilt toolchains - fast)
```
