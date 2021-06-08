> [!warning|iconVisibility:hidden|labelVisibility:hidden]
> Supported build platforms are: `Debian Buster|testing` - `Ubuntu Bionic|Focal|hirsute` - `Alpine 3.10 +` - including `docker` images of these platforms

> [!TIP|iconVisibility:hidden|labelVisibility:hidden] The preferred and recommended build paltform is Alpine linux.

`qbittorrent-nox` is a build of qbittorrent that does not include the desktop components. It instead come with a built in web interface and is used via the Linux command line. The web interface is accessed via a browser.

The build process can be difficult as there many independently complex dependencies involved. This build script helps lower the difficulty and makes building `qbittorrent-nox` as easy as it can be whilst also supporting multiple architectures, operating systems, some optimisations and patching options to tune the build.

These are the main dependencies we need to work with in order to build a fully functional and portable static binary for `qbittorrent-nox`.

| Dependencies |               Links to source                | Requirements |
| :----------: | :------------------------------------------: | :----------: |
|     zlib     |       <https://github.com/madler/zlib>       |   required   |
|   openssl    |     <https://github.com/openssl/openssl>     |   required   |
|    iconv     |  https://git.savannah.gnu.org/git/libiconv   |   required   |
|     icu      |      https://github.com/unicode-org/icu      |   optional   |
|    boost     |     <https://github.com/boostorg/boost>      |   required   |
|  libtorrent  |     https://github.com/arvidn/libtorrent     |   required   |
|    qtbase    |        <https://github.com/qt/qtbase>        |   required   |
|   qttools    |       <https://github.com/qt/qttools>        |   required   |
| qbittorrent  | <https://github.com/qbittorrent/qBittorrent> |   required   |

> [!note|iconVisibility:hidden|labelVisibility:hidden]
> `ICU` is an optional dependency and `libtorrent` and `qtbase` default to `iconv` if it is absent. If ICU is present `qtbase` will default to `ICU`
