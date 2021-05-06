Once the script has successfully configured the platform you can execute the help switch to see how it works and what options you have available to you.

```bash
bash ~/qbittorrent-nox-static.sh -h
```

### Switches and flags summarised

All switches and flags have a supporting help option that will provide dynamic content where applicable.

>[!NOTE] The `--boot-strap-release` and `--boot-strap-multi-arch` options are specific to GitHub actions but if you read `--help-boot-strap-release` you can see how to trigger `aarch64` builds on your local system.

```none
 Here are a list of available options

 Use: -b     or --build-directory       Help: -h-b     or --help-build-directory
 Use: -d     or --debug                 Help: -h-d     or --help-debug
 Use: -bs    or --boot-strap            Help: -h-bs    or --help-boot-strap
 Use: -bs-r  or --boot-strap-release    Help: -h-bs-r  or --help-boot-strap-release
 Use: -bs-ma or --boot-strap-multi-arch Help: -h-bs-ma or --help-boot-strap-multi-arch
 Use: -bs-a  or --boot-strap-all        Help: -h-bs-a  or --help-boot-strap-all
 Use: -i     or --icu                   Help: -h-i     or --help-icu
 Use: -lm    or --libtorrent-master     Help: -h-lm    or --help-libtorrent-master
 Use: -lt    or --libtorrent-tag        Help: -h-lt    or --help-libtorrent-tag
 Use: -m     or --master                Help: -h-m     or --help-master
 Use: -n     or --no-delete             Help: -h-n     or --help-no-delete
 Use: -o     or --optimize              Help: -h-o     or --help-optimize
 Use: -p     or --proxy                 Help: -h-p     or --help-proxy
 Use: -pr    or --patch-repo            Help: -h-pr    or --help-patch-repo
 Use: -qm    or --qbittorrent-master    Help: -h-qm    or --help-qbittorrent-master
 Use: -qt    or --qbittorrent-tag       Help: -h-qt    or --help-qbittorrent-tag

 Module specific help - flags are used with the modules listed here.

 Use: all or module-name          Usage: ~/qbittorrent-nox-static.sh all -i

 all         - Install all modules
 install     - optional Install the ~/qb-build/completed/qbittorrent-nox binary
 bison       - required Build bison
 gawk        - required Build gawk
 glibc       - required Build libc locally to statically link nss
 zlib        - required Build zlib locally
 icu         - optional Build ICU locally
 openssl     - required Build openssl locally
 boost       - required Download, extract and build the boost library files
 qtbase      - required Build qtbase locally
 qttools     - required Build qttools locally
 libtorrent  - required Build libtorrent locally with b2
 qbittorrent - required Build qbitorrent locally
```

For example, taking the `-h-bs` switch as an example, it will show different results based on the preceding switches provided:

<!-- tabs:start -->

<!-- tab: -h-bs -->

```bash
 Here is the help description for this flag:

 Creates dirs in this structure: ~/qb-build/patches/APPNAME/TAG/patch

 Add your patches there, for example.

 ~/qb-build/patches/libtorrent/1.2.13/patch

 ~/qb-build/patches/qbittorrent/4.3.5/patch
```

<!-- tab: -qm -lm -h-bs -->

```bash
 Here is the help description for this flag:

 Creates dirs in this structure: ~/qb-build/patches/APPNAME/TAG/patch

 Add your patches there, for example.

 ~/qb-build/patches/libtorrent/RC_1_2/patch

 ~/qb-build/patches/qbittorrent/master/patch
 ```

 <!-- tab: -qt release-4.2.5 -lt v2.0.3 -h-bs -->

 ```bash
Here is the help description for this flag:

 Creates dirs in this structure: ~/qb-build/patches/APPNAME/TAG/patch

 Add your patches there, for example.

 ~/qb-build/patches/libtorrent/2.0.3/patch

 ~/qb-build/patches/qbittorrent/4.2.5/patch
```

<!-- tabs:end -->

### Build - default profile

Install all default modules (ICU is skipped) and build `qbittorrent-nox` to the default build directory `qb-build/compelted`.

```bash
bash ~/qbittorrent-nox-static.sh all
```

### Build - modules (optional and mostly for debugging and testing)

You can build modules indivually, subject to this warning.

> [!warning] It's best to consider all indivual modules listed below as being dependent on the previous modules being built for that module to build successfully.

```bash
bash ~/qbittorrent-nox-static.sh module
```

Here are the list of supported modules:

```bash
bison (Debian based only)
gawk (Debian based only)
glibc (Debian based only)
zlib (default)
icu (optional on either platform)
openssl (default)
boost (default)
qtbase (default)
qttools (default)
libtorrent (default)
qbittorrent (default
```

### Build - paths

By default the script will built to a hard coded path defined by the scripts `$install_dir` variable as to avoid installing files to a server and causing conflicts.

>[!NOTE] This path is relative to the scripts location.

```bash
qb-build
```

You can modify this dynamically with the `-b` argument

> [!warning] The `-b` must be used in all commands provided to the script or default `qb-build` will be used instead.

> [!tip] The `-b` flag accepts both full `/opt` and relative `opt` paths.

```bash
bash ~/qbittorrent-nox-static.sh all -b "/opt"
```
