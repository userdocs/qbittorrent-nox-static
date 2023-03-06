v1.0.5 - 06-03-2023

	Modified the default behaviour of the Debian installation to not build `gawk` and `bison` by default. It will now install them via apt-get.

	There is a new switch `-dma` which will trigger the alternate mode and instead build `gawk` and `bison` from source.

v1.0.4 - 19-01-2023

	Changed: Dropped build support for older Buster-Bionic since they require a more modern gcc version to successfully build natively. Successful builds on a modern OS can be used there instead.

v1.0.3 - 15-07-2022

	Fixed: build - Libtorrent using b2 had checks against supplied tags to do version specific things that failed to match properly when using a pull request tag or non versioned branch. It now always check the version.hpp to determine the version in these build checks.
