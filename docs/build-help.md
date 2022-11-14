Once the script has successfully configured the platform you can execute the help switch to see how it works and what options you have available to you.

```bash
bash ~/qbittorrent-nox-static.sh -h
```

### ENV settings

> [!warning|iconVisibility:hidden|labelVisibility:hidden] `export` the variables listed below when you use them in your local env.

The script has some `env` settings that can trigger certain behaviour.

| Build variable                  | Default if unset                    | Options                            | example usage                                            |
| ------------------------------- | ----------------------------------- | ---------------------------------- | -------------------------------------------------------- |
| `libtorrent_version`            | `2.0`                               | `1.2` `2.0`                        | `export libtorrent_version=2.0`                          |
| `qbt_qt_version`                | `6.3`                               | `5.12` `5.15` `6.3` `6.3.1`        | `export qbt_qt_version=6.3`                              |
| `qbt_build_tool`                | `qmake`                             | `cmake`                            | `export qbt_build_tool=cmake`                            |
| `qbt_cross_name`                | empty = `unset` (default to OS gcc) | `x86_64` `aarch64` `armv7` `armhf` | `export qbt_cross_name=aarch64`                          |
| `qbt_patches_url`               | `userdocs/qbittorrent-nox-static`   | `username/repo`                    | `export qbt_patches_url=userdocs/qbittorrent-nox-static` |
| `qbt_workflow_files`            | empty = `unset` (defaults to no)    | `yes` `no`                         | `export qbt_workflow_files=yes`                          |
| `qbt_libtorrent_master_jamfile` | empty = `unset` (defaults to no)    | `yes` `no`                         | `export qbt_libtorrent_master_jamfile=yes`               |
| `qbt_optimise_strip`            | empty = `unset` (defaults to no)    | `yes` `no`                         | `export qbt_optimise_strip=yes`                          |
| `qbt_build_debug`               | empty = `unset` (defaults to no)    | `yes` `no`                         | `export qbt_build_debug=yes`                             |

> [!tip|iconVisibility:hidden|labelVisibility:hidden] If you see more variables in the script but they are not listed here they are Github Action specific configured by workflows.

> [!note|iconVisibility:hidden|labelVisibility:hidden] If you set `qbt_build_tool=cmake` and `qt_version=6.2`  with the switch `-qm` you can build against QT6.

### Switches and flags summarised

All switches and flags have a supporting help option that will provide dynamic content where applicable.

>[!note|iconVisibility:hidden|labelVisibility:hidden] The `--boot-strap-release` and `--boot-strap-multi-arch` options are specific to GitHub actions but if you read `--help-boot-strap-release` you can see how to trigger `aarch64|armv7` builds on your local system using Alpine/Debian/Ubuntu via docker.

```none
 Here are a list of available options

 Use: -b     or --build-directory       Help: -h-b     or --help-build-directory
 Use: -bv    or --boost-version         Help: -h-bv    or --help-boost-version
 Use: -c     or --cmake                 Help: -h-c     or --help-cmake
 Use: -d     or --debug                 Help: -h-d     or --help-debug
 Use: -bs    or --boot-strap            Help: -h-bs    or --help-boot-strap
 Use: -bs-c  or --boot-strap-cmake      Help: -h-bs-c  or --help-boot-strap-cmake
 Use: -bs-r  or --boot-strap-release    Help: -h-bs-r  or --help-boot-strap-release
 Use: -bs-ma or --boot-strap-multi-arch Help: -h-bs-ma or --help-boot-strap-multi-arch
 Use: -bs-a  or --boot-strap-all        Help: -h-bs-a  or --help-boot-strap-all
 Use: -i     or --icu                   Help: -h-i     or --help-icu
 Use: -lm    or --libtorrent-master     Help: -h-lm    or --help-libtorrent-master
 Use: -lt    or --libtorrent-tag        Help: -h-lt    or --help-libtorrent-tag
 Use: -m     or --master                Help: -h-m     or --help-master
 Use: -ma    or --multi-arch            Help: -h-ma    or --help-multi-arch
 Use: -n     or --no-delete             Help: -h-n     or --help-no-delete
 Use: -o     or --optimize              Help: -h-o     or --help-optimize
 Use: -p     or --proxy                 Help: -h-p     or --help-proxy
 Use: -pr    or --patch-repo            Help: -h-pr    or --help-patch-repo
 Use: -qm    or --qbittorrent-master    Help: -h-qm    or --help-qbittorrent-master
 Use: -qt    or --qbittorrent-tag       Help: -h-qt    or --help-qbittorrent-tag
 Use: -s     or --strip                 Help: -h-s     or --help-strip

 Module specific help - flags are used with the modules listed here.

 Use: all or module-name          Usage: ~/qbittorrent-nox-static.sh all -i

 all ---------------- optional Recommended method to install all modules
 install ------------ optional Install the ~/qbt-build/completed/qbittorrent-nox binary
 bison -------------- required Build bison
 gawk --------------- required Build gawk
 glibc -------------- required Build libc locally to statically link nss
 zlib --------------- required Build zlib locally
 iconv -------------- required Build iconv locally
 icu ---------------- optional Build ICU locally
 openssl ------------ required Build openssl locally
 boost -------------- required Download, extract and build the boost library files
 libtorrent --------- required Build libtorrent locally
 double_conversion -- required A cmakke + Qt6 build compenent on modern OS only.
 qtbase ------------- required Build qtbase locally
 qttools ------------ required Build qttools locally
 qbittorrent -------- required Build qbittorrent locally

 env help - supported exportable evironment variables

 export qbt_libtorrent_version="" - options 1.2 2.0
 export qbt_qt_version="" --------- options 5,5.15,6,6.2,6.3 and so on
 export qbt_build_tool="" --------- options qmake cmake
 export qbt_cross_name="" --------- options aarch64 armv7 armhf
 export qbt_patches_url="" -------- options userdocs/qbittorrent-nox-static or usee your full/shorthand github repo
 export qbt_workflow_files="" ----- options yes no - use qbt-workflow-files repo for dependencies - custom tags will override
 export qbt_optimise_strip="" ----- options yes no - strip binaries to reduce file size - cannot be used with debug
 export qbt_build_debug="" -------- options yes no - create a full debug build for use with gdb - cannot be used with strip

 Currrent settings

 qbt_libtorrent_version="2.0"
 qbt_qt_version="5"
 qbt_build_tool="qmake"
 qbt_cross_name=""
 qbt_patches_url="userdocs/qbittorrent-nox-static"
 qbt_workflow_files="no"
 qbt_libtorrent_master_jamfile="no"
 qbt_optimise_strip="no"
 qbt_build_debug="no"
```

For example, taking the `-h-bs` switch as an example, it will show different results based on the preceding switches provided:

<!-- tabs:start -->

<!-- tab: -h-bs -->

```bash
 Here is the help description for this flag:

 Creates dirs in this structure: ~/qbt-build/patches/APPNAME/TAG/patch

 Add your patches there, for example.

 ~/qbt-build/patches/libtorrent/1.2.13/patch

 ~/qbt-build/patches/qbittorrent/4.3.5/patch
```

<!-- tab: -qm -lm -h-bs -->

```bash
 Here is the help description for this flag:

 Creates dirs in this structure: ~/qbt-build/patches/APPNAME/TAG/patch

 Add your patches there, for example.

 ~/qbt-build/patches/libtorrent/RC_1_2/patch

 ~/qbt-build/patches/qbittorrent/master/patch
```

 <!-- tab: -qt release-4.2.5 -lt v2.0.3 -h-bs -->

 ```bash
 Here is the help description for this flag:

 Creates dirs in this structure: ~/qbt-build/patches/APPNAME/TAG/patch

 Add your patches there, for example.

 ~/qbt-build/patches/libtorrent/2.0.3/patch

 ~/qbt-build/patches/qbittorrent/4.2.5/patch
 ```

<!-- tabs:end -->

### Build - default profile

Install all default modules (ICU is skipped) and build `qbittorrent-nox` to the default build directory `qbt-build/compelted`.

```bash
bash ~/qbittorrent-nox-static.sh all
```

### Build - modules (optional and mostly for debugging and testing)

You can build modules individually, subject to this warning.

> [!warning|iconVisibility:hidden|labelVisibility:hidden] It's best to consider all individual modules listed below as being dependent on the previous modules being built for that module to build successfully.

```bash
bash ~/qbittorrent-nox-static.sh module
```

Here are the list of supported modules:

```bash
bison (Debian based only)
gawk (Debian based only)
glibc (Debian based only)
zlib (default)
iconv (default)
icu (optional on either platform)
openssl (default)
boost (default)
double_conversion (default for Qt6 on modern OS Bullseye / Jammy)
qtbase (default)
qttools (default)
libtorrent (default)
qbittorrent (default)
```

### Build - paths

By default the script will built to a hard coded path defined by the scripts `$install_dir` variable as to avoid installing files to a server and causing conflicts.

>[!note|iconVisibility:hidden|labelVisibility:hidden] This path is relative to the scripts location.

```bash
qbt-build
```

You can modify this dynamically with the `-b` argument

> [!warning|iconVisibility:hidden|labelVisibility:hidden] The `-b` must be used in all commands provided to the script or default `qbt-build` will be used instead.

> [!tip|iconVisibility:hidden|labelVisibility:hidden] The `-b` flag accepts both full `/opt` and relative `opt` paths.

```bash
bash ~/qbittorrent-nox-static.sh all -b "/opt"
```
