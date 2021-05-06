In summary, [qbittorrent-nox-static](https://github.com/userdocs/qbittorrent-nox-static) project is a `bash` build script that compiles a static `qbittorrent-nox` binary using the latest available dependencies from their source. These statically linked binaries can run on any matching CPU architecture and are not OS specific. This means you can run a  Alpine musl `x86_64` build on CentOS - Fedora - OpenSuse - Debian Stretch - Ubuntu Xenial and more. 

> [!TIP|iconVisibility:hidden|labelVisibility:hidden] The preferred and recommended build paltform is Alpine linux.

The build process is complex as there many independantly complex dependencies involved. These are the main dependencies we need to work with in order to build a fully functional and portable static binary for `qbittorrent-nox`.

-  `zlib`
-  `openssl`
-  `ICU`
-  `boost`
-  `libtorrent`
-  `qtbase`
-  `qttools`
-  `qbittorrent`

> [!tip|iconVisibility:hidden|labelVisibility:hidden]
> `ICU` is an optional depencency and `libtorrent` and `qtbase` default to `iconv` if it is absent. If ICU is present `libtorrent` and `qtbase` default to `ICU`

On supported platforms the `qbittorrent-nox-static.sh` will perform these three main tasks:

> [!warning|iconVisibility:hidden|labelVisibility:hidden]
> Supported platforms are: `Debian Buster` - `Ubuntu Bionic|Focal` - `Alpine 3.10 +` - including `docker` images of these platforms

-  Update the system and install the core build dependencies - Requires root privileges if any dependencies are missing.
-  Install and build the `qbittorrent-nox` dependencies locally with no special privileges required.
-  Build a fully static and portable `qbittorrent-nox` binary which automatically uses the latest version of all supported dependencies.

Here is an example successful build profile:

```none
qBittorrent 4.3.5 was built with the following libraries:

Qt: 5.15.2
Libtorrent: 1.2.13.0
Boost: 1.76.0
OpenSSL: 1.1.1k
zlib: 1.2.11
```

<!-- tabs:start -->

<!-- tab: Debian and Ubuntu Linux -->

The script creates a fully static `qbittorrent-nox` binary using [libc](https://www.gnu.org/software/libc/).

The final result will show this when using `ldd`

```bash
ldd ~/qb-build/bin/qbittorrent-nox
```

Gives this result:

```bash
not a dynamic executable
```

<!-- tab:Alpine Linux -->

The script creates a fully static `qbittorrent-nox` binary using [musl](https://wiki.musl-libc.org/).

The final result will show this when using `ldd`

```bash
ldd ~/qb-build/bin/qbittorrent-nox
```

Gives this result:

```bash
statically linked
```

<!-- tabs:end -->
