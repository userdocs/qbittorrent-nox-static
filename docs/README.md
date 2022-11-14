> [!warning|iconVisibility:hidden|labelVisibility:hidden] Supported build platforms are: `Debian Buster|Bullseye` - `Ubuntu Bionic|Focal|Jammy` - `Alpine 3.10 +` - native or via `docker` images

> [!TIP|iconVisibility:hidden|labelVisibility:hidden] The preferred and recommended build platform is Alpine Linux and the recommended method is via docker.

`qbittorrent-nox` is a build of qBittorrent that does not include the desktop components. Instead it is used via the Linux command line and comes with a built in Qt web interface. The web interface is accessed via a browser.

The build process has many independently complex dependencies involved. This build script helps lower the difficulty and makes building `qbittorrent-nox` statically as easy as it can be whilst also supporting multiple architectures, operating systems, dependency variations, optional optimizations and patching options to tune the build.

These are the main dependencies we need to work with in order to build a fully functional and portable static binary for `qbittorrent-nox`.

|   Dependencies    |               Links to source                |    Build OS     | Requirements |
| :---------------: | :------------------------------------------: | :-------------: | :----------: |
|       bison       |         http://ftp.gnu.org/gnu/bison         |   Debian only   |   required   |
|       gawk        |         http://ftp.gnu.org/gnu/gawk          |   Debian only   |   required   |
|       glibc       |         http://ftp.gnu.org/gnu/libc          |   Debian only   |   required   |
|       zlib        |     <https://github.com/zlib-ng/zlib-ng>     | Debian + Alpine |   required   |
|      openssl      |     <https://github.com/openssl/openssl>     | Debian + Alpine |   required   |
|       iconv       |       http://ftp.gnu.org/gnu/libiconv        | Debian + Alpine |   required   |
|        icu        |      https://github.com/unicode-org/icu      | Debian + Alpine |   optional   |
|       boost       |     <https://github.com/boostorg/boost>      | Debian + Alpine |   required   |
|    libtorrent     |     https://github.com/arvidn/libtorrent     | Debian + Alpine |   required   |
| double conversion | https://github.com/google/double-conversion  | Debian + Alpine |   required   |
|      qtbase       |        <https://github.com/qt/qtbase>        | Debian + Alpine |   required   |
|      qttools      |       <https://github.com/qt/qttools>        | Debian + Alpine |   required   |
|    qbittorrent    | <https://github.com/qbittorrent/qBittorrent> | Debian + Alpine |   required   |

> [!note|iconVisibility:hidden|labelVisibility:hidden] `ICU` is an optional dependency and `libtorrent` and `qtbase` default to `iconv` if it is absent. If ICU is present `qtbase` will default to `ICU`
