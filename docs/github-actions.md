There are some actions created that will build the binary and create and artifacts. They can be viewed here

<https://github.com/userdocs/qbittorrent-nox-static/actions>

All these action are triggered manually by clicking on the action running the workflow.

You can fork the repo and build it yourself.

Patching will work with actions as long as you configure it correctly.

These the currently available actions.

**Note:** `qbittorrent-nox multi build` also generates a release based on the qbittorrent and libtorrent tags used. The release is created when the first matrix build completes and the other builds update this release as they complete.

```bash
aarch64.yml # build to this arch using the lasted release of supported versions
amd64.yml # build to this arch using the lasted release of supported versions

debian_based_CI.yml # CI on x86_64 Debian buster/sid Ubuntu Focal/hirsute to amke sure it all works.

icu_aarch64.yml # build to this arch with ICU using the lasted release of supported versions
icu_amd64.yml # build to this arch with ICU using the lasted release of supported versions

matrix_qmake_cmake_release.yml # qbittorrent-nox qmake, cmake, lintorrent v1 and v2 multi build (x86_64 armhf armv7 aarch64 + release cross built via musl prebuilt toolchains - fast)

patch_amd64.yml # patch testing action
patch_icu_amd64.yml # patch testing action with ICU

qt6_RC_2_0_icu_aarch64.yml # This will fail at building qbittorrent until qt6 compatible fixes are pushed to master
qt6_RC_2_0_icu_amd64.yml # This will fail at building qbittorrent until qt6 compatible fixes are pushed to master

RC_2_0_aarch64.yml # build to this arch using libtorrent RC_2_0 branch and the latest qbittorrent release
RC_2_0_amd64.yml # build to this arch using libtorrent RC_2_0 branch and the latest qbittorrent release
RC_2_0_icu_aarch64.yml # build to this arch using ICU and the libtorrent RC_2_0 branch and the latest qbittorrent release
RC_2_0_icu_amd64.yml # build to this arch using ICU and the libtorrent RC_2_0 branch and the latest qbittorrent release
```
