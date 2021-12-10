On supported platforms the `qbittorrent-nox-static.sh` will perform these three main tasks:

-  Update the system and install the core build dependencies - Requires root privileges if any dependencies are missing.
-  Install and build the `qbittorrent-nox` dependencies locally with no special privileges required.
-  Build a fully static and portable `qbittorrent-nox` binary which automatically uses the latest version of all supported dependencies.

Here is an example successful build profile:

```none
qBittorrent 4.3.9 was built with the following libraries:

Qt: 5.15.3
Libtorrent: 1.2.15.0
Boost: 1.78.0
OpenSSL: 3.0.0
zlib: 1.2.11.zlib-ng
```

<!-- tabs:start -->

<!-- tab: Debian and Ubuntu Linux -->

The script creates a fully static `qbittorrent-nox` binary using [libc](https://www.gnu.org/software/libc/).

The final result will show this when using `ldd`

```bash
ldd ~/qbt-build/bin/qbittorrent-nox
```

Gives this result:

```bash
not a dynamic executable
```

<!-- tab:Alpine Linux -->

The script creates a fully static `qbittorrent-nox` binary using [musl](https://wiki.musl-libc.org/).

The final result will show this when using `ldd`

```bash
ldd ~/qbt-build/bin/qbittorrent-nox
```

Gives this result:

```bash
statically linked
```

<!-- tabs:end -->
