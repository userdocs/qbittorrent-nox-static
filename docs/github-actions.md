There are some actions created that will build the binaries and create and artifacts. They can be viewed here:

<https://github.com/userdocs/qbittorrent-nox-static/actions>

Most of these actions are triggered manually by clicking on the action and running the workflow meaning you can fork the repo and use the workflows you require. Patching will work with the `multi_arch` actions as long as you configure it correctly in the action first.

These are the currently available actions.

>  [!TIP|iconVisibility:hidden|labelVisibility:hidden] `matrix_multi_build_and_release.yml` also generates releases based on the qbittorrent and libtorrent tags used. The release is created when the first matrix build completes and the other builds update this release as they complete.

```bash
# CI triggered on pushes to the build script. Tests on x86_64 Debian buster/sid Ubuntu Focal/hirsute to make sure it all works on these platforms.
debian_based_CI.yml

 # qbittorrent-nox qmake, cmake, libtorrent v1 and v2 multi build and release across these architectures - x86_64 armhf armv7 aarch64 cross built via musl prebuilt toolchains. 32 builds are created. 16 per release.
matrix_multi_build_and_release.yml
# Same as above but with options to specificy tags so that I can update previous releases.
matrix_multi_build_and_release_customs_tags.yml


# All these multi arch specific actions will build to the specificed arch using qmake and cmake using the latest releases of qbittorrent and libtorrent, with and without icu for libtorrent v1 an v2. 8 articafts per action are created.
multi_x86_64_artifacts.yml
multi_aarch64_artifacts.yml 
multi_armv7_artifacts.yml 
multi_armhf_artifacts.yml

# A tesrt action. This will fail at building qbittorrent until qt6 compatible fixes are pushed to master
qt6_RC_2_0_icu_amd64.yml

```
