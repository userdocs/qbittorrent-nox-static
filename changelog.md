### v2.2.2 - 17/08/2025

`qbt-nox-static.bash` was fully merged into `qbittorrent-nox-static.sh` so that the scripts no longer have significantly different code approaches to the same outcomes.

To maintain expected behavior I only needed to make a small adjustment to the script to make it behave the same way without having to support two versions fo the same script.

This essentially completes the transition from the legacy script to the current without any breaking changes.

fixed:
    - install binary function was not working correctly and has been updated.
    - fixed building glibc in debug mode due to incorrect flags
    - fixed glibc utf-8 warning when building qbittorrent. install the locale C.UTF-8 from glibc source dir
    - fix alpine version check properly compare versions.
    - fixed boost version check that was creating a malformed url for github and beta releases.

### v2.2.1 - 13/08/2025

Debian support bumped to trixie

Debian crossbuild now supports riscv64

`cmake`/`ninja` no longer installed via external builds for any support OS. Related code and arguments removed.

They are only installed via `apt` for Debian based and `apk` for Alpine.

The reason the external tools existed was to overcome issues with outdated or missing stable release packages.

This not be an issue since `trixie` `cmake` is `3.31` or newer and `ninja-build` was reintroduced as an Alpine package some time ago. There was no specific benefit to using them other than enabling building.

This makes the `qbt-cmake-ninja-crossbuilds` and `qbt-ninja-build` redundant as the script no longer depends on them.

### v2.2.0 - 26/07/2025

Context: As the qbt-musl-cross-make toolchains were being revised to properly apply `-static-pie` patches, some issues needed to be resolved that resulted in a rework of some things.

| Status       | Component       | Link                                                                                             |
| ------------ | --------------- | ------------------------------------------------------------------------------------------------ |
| (patched)    | qBittorrent     | https://github.com/qbittorrent/qBittorrent/pull/22987                                            |
| (unresolved) | zlib-ng         | https://github.com/zlib-ng/zlib-ng/issues/1936                                                   |
| (patched)    | musl-cross-make | https://github.com/richfelker/musl-cross-make/tree/master/patches/binutils-2.44                  |
| (patched)    | musl-cross-make | https://github.com/richfelker/musl-cross-make/tree/master/patches/gcc-15.1.0                     |
| (resolved)   | openssl         | n/a - it was an issue with using `LDFLAGS=-static` which triggers unexpected behavior in openssl |

___

- Added the choice of [zlib](https://github.com/madler/zlib) and [zlib-ng](https://github.com/zlib-ng/zlib-ng), defaulting to `zlib` as `zlib-ng` has unresolved arch issues. This shows as `-motley`
- Added the ability for the script to fully cross build all dependencies without using `qemu` emulation.
  - Qemu applies when cross building building QT6 or ICU
  - `qbt_with_qemu` - default: `yes` - if this is set to `no` abd cross compiling then the modules of `icu_host_deps` `qtbase_host_deps` `qttools_host_deps` are added to the installation to bootstrap required host versions.
  - `qbt_host_deps` - default: `no` - if this is set to `yes` the script will pull in prebuilt host dependencies from here - <https://github.com/userdocs/qbt-host-deps>
- `iconv` is no longer installed when using libtorrent `v2` as it was only ever a dependency of libtorrent `v1.2`

> [!NOTE]
> `qbt_host_deps` will always be mirrored to the latest release version.

A lot of general refactoring, formatting and minor bug fixes.

More consistent use if build flags and when the are applied.
More consistent debug triggering so all parts are built in debug mode.
caching behavior tweaked - use workflow files when it can.

### v2.1.3 - 29/06/2025

problem: when the `-lt` flag was used with libtorrent `v1.2` like `-lt v1.2.20` boost was not being defaulted to `boost-1.86.0` as it does when setting the env equivalent, causing a build error when libtorrent was built.

fix: the flag now properly checks and sets boost to `boost-1.86.0` when libtorrent `v1.2` is being built via [e11d7d5](https://github.com/userdocs/qbittorrent-nox-static/commit/e11d7d51b5a0a6a99fcac6ae44c4603286e9a598)

### v2.1.2 - 18/05/2025

fix: `double_conversion` all versions - apply patch for increasing cmake bounds in `CMakeLists.txt` via this [patch](https://github.com/google/double-conversion/commit/0604b4c18815aadcf7f4b78dfa6bfcb91a634ed7)

fix: `v2.0.18` only - `qbittorrent-nox-static.sh` glibc configure flags. An argument `--enable-cet` was missing from this when backporting changes from `qbt-nox-static.bash`

### v2.1.2 - 29/04/2025

build flags: `-fcf-protection=full` (`x86_64`) and `-mbranch-protection=standard` (`aarch64`)

Don't use certain arch specific flags when cross compiling as they will not work with gcc 15 and were probably silently ignored by gcc 14 and previous.

Only use them when not cross compiling

### v2.1.1 - 18/02/2025

build flags tweaked using this information as a guide:

https://best.openssf.org/Compiler-Hardening-Guides/Compiler-Options-Hardening-Guide-for-C-and-C++.html#tldr-what-compiler-options-should-i-use

Hardening is preferred over performance.

### v2.1.0 - 20/01/2025

`qbt-nox-static.bash` will be created alongside the `qbittorrent-nox-static.sh`.

`qbt-nox-static.bash` ≥ `v2.1.0`

`qbt-nox-static.bash` will start with `v2.1.0` and `qbittorrent-nox-static.sh` will be frozen at `v2.0.15` going forward. This is to avoid breaking anything by replacing `qbittorrent-nox-static.sh` with `qbt-nox-static.bash` and removing access to the old file. `v2.1.0` is not really changing the outcome but the behavior of the script towards that outcome. So the least disruptive way is the opt-in route. I also wanted to change the extension from `sh` to `bash` as it is a bash script.

There is feature parity between the two scripts as of this change. All major changes, fixes and tweaks are applied to both scripts with the exception of the reworked dependency and module installation logic which breaks expected behavior of the script.

#### Main changes

A reworked dependency and module installation logic, which has changed the default behavior of the script.

Reasoning: The script was designed to be run in a docker and needs `curl` and `git` to perform basic test functions. So it would automatically try to install all deps from a single array when run as root or with sudo to be able to then do the basic interactions. This was not ideal behavior as it would behave the same way on a host system whereas in a docker it didn't really matter. This required reworking how dependencies were checked, managed and installed.

#### Changes unique to `qbt-nox-static.bash`

- The script no longer tries to modify the host or create files if just called by its name. It will do basic dependency checks and offer options to install what's needed.
- It can now just install the required test dependencies or perform basic functions if they are already installed, meaning the basic features and help functions are usable without installing the full suite of dependencies.
- dependency specific modules new modules unique to this check: `update` | `install_test` | `install_core` | `bootstrap_deps`

Changes applied to both `qbt-nox-static.bash` and `qbittorrent-nox-static.sh`

- Removed build script support for buster, focal and jammy due to conflicts with updated build flags and will support current releases only going forward.
  - Builds are fully static so build on a modern OS to use on older systems.
  - Or use Github by forking the repo and running the workflows. You don't need to build on the target.
- Revised the optimization and build flags system to be more modern and useful, which breaks building on some older systems. Though this really only applies to debian hosts and the primary method is Alpine.
- changed: optimize still just applies `march-native` on non crossbuilds but now you can export `CFLAGS` `CPPFLAGS` `CXXFLAGS` `LDFLAGS` in the main env and they will be appended to the builds.
- fixed: optimize was not working as intended for being spelled inconsistently, optimise/optimize, so the checks for cross-building were not correct.
- all build optimization stuff moved to a unified function `_custom_flags` instead of being spread out across the script.
- Alpine only - if building using native gcc on the host it will attempt to use `-flto` - does not do this on crossbuilding as it does not work.
- General refactoring towards more consistent use of array data throughout the script with a preference towards associative arrays.
- fixed: standards checking - checks are more targeted to include os version names so as to avoid certain bad build combinations
- new: a new flag `-bs-e` that dumps a template `.qbt_env` file with all env vars that are unset then exits.
- crossbuild toolchains won't extract every time you run the script and will also now determine if you have the correct toolchains if you change the settings and not just assume.
- many consistency tweaks, minor bug fixes and streamlining of code.
- credits: Borrowed some build flags from here [qbittorrent/docker-qbittorrent-nox](https://github.com/qbittorrent/docker-qbittorrent-nox/blob/main/Dockerfile#L59-L61)

> For example: `release-5.0.3` on Debian Bullseye. Before it would have set `cxx20` and then failed when building qBittorrent. Now it won't try to build and give a warning whilst still allowing building older combos on that host.

### v2.0.15 - 20/01/2025

see `v2.1.0` changelog

### v2.0.14 - 31/12/2024

fix: libtorrent `v1.2` and boost `1.86.0` check to not ignore `RC_1_2`

fix: the `_apply_patches` function was assuming the remote default branch name of `master` which made it fail the check. It now tests for the remote default branch of a patch repo and uses that.

fix: boost source URL. jfrog source is just a problem. Script now defaults to github boost release and falls back to archives.boost.i, jfrog is purged.

fix: Some typos

### v2.0.13 - 31/12/2024

Added `qbt_build_dir` as a definable env variable. This variable is to set the build directory which defaults to `qbt-build` if unset

### v2.0.12 - 17/12/2024

Default to `boost-1.86.0` for `RC_1_2` or `v1.2.x` builds because `RC_1_2` has not been updated to support the (deprecated) features removed in `boost-1.87.0` so the build will fail.

This method allows the user to override the setting by providing a valid boost tag using `qbt_boost_tag` or `-bt`

fix: changed `-bt | --boost-version` to `-bt | --boost-tag` for consistency. It was always supposed to be `--boost-tag` since that is what we are providing and testing via this flag.

### v2.0.11 - 13/10/2024

Disable glib tests on zlib-ng <https://github.com/userdocs/qbittorrent-nox-static/pull/173>

Update contributor info

minor changes - <https://github.com/userdocs/qbittorrent-nox-static/commit/e4a674fa3832e0c0d6950539adac9d1d8d00d0e7>

### v2.0.10 - 05/10/2024

Make `cmake` the default build tool with the release of qBittorrent v5

### v2.0.9 - 14/05/2024

Change default c++ standard used for newer build combinations from 23 to 20.

### v2.0.8 - 12-04-2024

Fixed a regression with `-o` where part of the code was left in and duplicated after introducing a check for cross compilation, causing the positional parameters to be shifted twice, breaking things.

fix - <https://github.com/userdocs/qbittorrent-nox-static/commit/b51e1ef356fbdbd3f2f93f2b2a8a6279b99e5f22>

### v2.0.7 - 12-02-2024

Added: a boost download function to combine some logic around fallback URLs and minimize external calls.

Added: a check to build combos for qt + cmake to prevent env files trying to build a known bad combo.

fixed: modules check for whole word and not accept partial matches

fixed: associative arrays declared earlier and in a group to allow changing settings via functions

### v2.0.6 - 2024-01-27

New flag: `-si` / `--static-ish` for Debian, Ubuntu, and Alpine platforms. This flag disables LDFLAGS static linking, allowing the OS `libc` to be dynamically linked.

You cannot use this flag with cross compilation, only native host builds.

Tests were added for `static-ish` and `optimize` to check for bad combinations, exiting the script with a helpful reason when used in combination with cross compilation, as the build will fail.

### v2.0.5 - 23-01-2024

Codename: Copilot made me do it

- Improved readability of the colour variables used throughout the script.
- Some minor tweaks to OS detection
- Moved some things around or into their own functions and some error handling.
- Some changes to how cxx standard is handled and defined so the script will default to 23 when the conditions are met.
- minor bug fix - `qbt_libtorrent_version` displays correctly when using an RC github tag.

Support for Ubuntu Noble added - Mantic removed as it's preferred to support LTS releases

- Ubuntu Focal - Jammy - Noble
- Debian Bullseye - Bookworm

### v2.0.4 - 16-01-2024

Make sure the workflow override applies when using cached dependencies

Allow patching from a remote raw git patch via URL - a file called `url` in the patch repo for the module version that contains a URL to the raw patch
other minor tweaks and cosmetic changes

### v2.0.3 - 27-12-2023

Fixed a regression from the V2 update where the host arch for `zlib-ng` was incorrectly set to `x86_64`, regardless of the actual host arch, when building on a non `x86_64` host to the same target arch (not cross building).

<https://github.com/userdocs/qbittorrent-nox-static/issues/131>

### v2.0.2 - 26-05-2023

Set `ICU` default to `no`. It does not need to be forced to on as there is no longer a related bug and it also makes more sense when considering the `-i` toggle.

### v2.0.1 - 15-05-2023

Bug fix: `skip_icu` was being unset and defaulting to no. It is no longer unset and if set to skipped when using the module directly will still skip it.

### v2.0.0 - 03-04-2023

There have been various breaking changes in the supporting architecture that affect the script and require updating to v2.0.0 from v1.1.0 or earlier.

A lot of changes and tweaks to workflows and supporting repos to make sure things are as size efficient as they can be. For example, gz to xz where possible.

Alpine Crossbuild tools are 70% reduced in size.

The script can now build for these arches using musl or debian though workflows and releases may not target them all yet.

armel armhf armv7 aarch64 x86_64 x86 s390x powerpc ppc64el mips mipsel mips64 mips64el riscv64

v2 is is an overhaul that aims to be more sensibly coded and and use associative arrays to handle the URL data properly. Less obfuscated and consistent in how it uses this data.

docs to be updated soon.

A quick summary of main changes and features from v1.5.0 through vto 2.0.0

- No more bison or gawk building. They are OS dependencies now and need to be installed on the host.
- Alpine only - Increased multiarch target support, updated musl cross tools and optimised size.
- A caching mechanism for files to store and manage download dependencies to avoid re-downloading them across builds.
- Any valid boost tag can be provided including beta tags. It was not a tag based check before.
- Any valid qt tag can be provided including beta tags.
- patches system reworked to allow patching any module. Source code files can also be used from app_version/source
- Improved the way tags are checked and the changes applied to be more consistent throughout the script.
- Removed any trace of gnu.org for being a really unreliable source location.
- optimised multiarch configurations and multiarch various bug fixes.
- Alpine only - Ninja is now prebuilt instead of locally built.
- All url data can be viewed using the -sdu switch.
- Lots of small tweaks, removing code and simplifying code and rebuilding functions.

### v1.1.0 - 18-03-2023

Breaking changes: -bv 1.81.0 have been replaced with -bt boost-1.81

Reason: This check is now very similar to the -lt and -qt switches to it makes sense to bring it inline with how those are used.

Changes:

The script has gone through a general refactoring with many code optimizations, simplifications and improvements starting from v1.0.6.

Features:

Caching and cache management via -cd

Tag switches are more versatile in how they select source files based on tag input. Trying to use archives first but automatically falling back to folders when required.

More env options introduced to make setting most dynamic features available via env settings.

New switch options added.

### v1.0.6 - 07-03-2023

Lot of tweaks and changes.

cache files method is now integrated into the script as a result of the URL function changes.

Refactored URL function. It now uses associative arrays to hold the data for URLs, tags and versions. This makes the data more structured and easier to use consistently throughout the script.

Changed all instances of echo -e to printf %b

Added a method to using an existing local git repo as a cached source. It will clone a folder with the matching app name in the cache path provided and clone, if it exists.

It will respect manually specified tags and checkout those from the clone folders.

The lowercase naming convention of the applications must be used in the cache_path/folder_name like cache_path/qbittorrent

It must be a git repo

### v1.0.5 - 06-03-2023

Modified the default behavior of the Debian installation to not build gawk and bison by default. It will now install them via apt-get.

There is a new switch -dma which will trigger the alternate mode and instead build gawk and bison from source.

### v1.0.4 - 19-01-2023

Changed: Dropped build support for older Buster-Bionic since they require a more modern gcc version to successfully build natively. Successful builds on a modern OS can be used there instead.

### v1.0.3 - 15-07-2022

Fixed: build - Libtorrent using b2 had checks against supplied tags to do version specific things that failed to match properly when using a pull request tag or non versioned branch. It now always check the version.hpp to determine the version in these build checks.
