
To properly debug a segfault the build will need to have been built with libtorrent and qbitorrent debug symbols.

One of the issues here is that with the static build the libtorrent debug symbols can add 100MB to the file size.

This can be done using the `-d` flag or `export qbt_build_debug=on`.

I am considering the best way to release a debug build but in the mean time you can build it if you need.
