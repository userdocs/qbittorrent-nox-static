
This build tool is an end user complexity inverter. It makes building a fully static and optimised qbittorrent-nox binary easy.

Managing the various complexities surrounding each of the dependencies in order to successfully build them as part of the whole.

These are the main dependencies we need to work with in order to build a fully functional and portable static binary for `qbittorrent-nox`.

|   Dependencies    |                Links to source                |    Build OS     | Requirements |
| :---------------: | :-------------------------------------------: | :-------------: | :----------: |
|       glibc       |         http://ftp.gnu.org/gnu/libc        |     Debian      |   required   |
|   zlib/zlib-ng    |     https://github.com/zlib-ng/zlib-ng      | Debian + Alpine |   required   |
|      openssl      |     https://github.com/openssl/openssl      | Debian + Alpine |   required   |
|       iconv       |       http://ftp.gnu.org/gnu/libiconv       | Debian + Alpine |   required   |
|        icu        |     https://github.com/unicode-org/icu      | Debian + Alpine |   optional   |
|       boost       |      https://github.com/boostorg/boost      | Debian + Alpine |   required   |
|    libtorrent     |    https://github.com/arvidn/libtorrent     | Debian + Alpine |   required   |
| double conversion | https://github.com/google/double-conversion | Debian + Alpine |   required   |
|      qtbase       |        https://github.com/qt/qtbase        | Debian + Alpine |   required   |
|      qttools      |        https://github.com/qt/qttools       | Debian + Alpine |   required   |
|    qbittorrent    | https://github.com/qbittorrent/qBittorrent  | Debian + Alpine |   required   |
