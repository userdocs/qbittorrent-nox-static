On supported platforms the `qbittorrent-nox-static.sh` will perform these three main tasks:

-   Update the system and install the core build dependencies - Requires root privileges if any dependencies are missing.
-   Install and build the `qbittorrent-nox` dependencies locally with no special privileges required.
-   Build a fully static and portable `qbittorrent-nox` binary which automatically uses the latest version of all supported dependencies.

Here is an example successful build profile:

```none
qBittorrent 4.4.5 was built with the following libraries:

Qt: 6.5.0
Libtorrent: 2.0.8
Boost: 1.81.0
OpenSSL: 3.0.7
zlib: 1.2.12.zlib-ng
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

The script can do a lot of helpful things to make building and deploying a fully static qBittorrent binary about as easy as it's going to get.

It can do lots of helpful things and is tightly integrated with Github workflows to make forking and using the project and workflows very intuitive.
