# qbittorrent-nox-static

A build script for qBittorent-nox to create a partially or fully static using the current releases of the main dependencies.

See here for binaries I have built - [Downloads](https://github.com/userdocs/qbittorrent-nox-static#download-and-install-static-builds)

## Info

There are 3 scripts for 2 platforms.

### Debian or Ubuntu platforms

`staticish` - Recommended - creates a mostly static binary that is can be moved to another matching platform. For example you can build on Debian 10 and run on Debian 10 because Glibc is dynamically linked linked to the build platform.

~~~
ldd qbittorrent-nox
~~~

Gives this result:

~~~
linux-vdso.so.1
libdl.so.2 => /lib/x86_64-linux-gnu/libdl.so.2
libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0
libstdc++.so.6 => /usr/lib/x86_64-linux-gnu/libstdc++.so.6
libm.so.6 => /lib/x86_64-linux-gnu/libm.so.6
libgcc_s.so.1 => /lib/x86_64-linux-gnu/libgcc_s.so.1
libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6
/lib64/ld-linux-x86-64.so.2
~~~

`glibc` - creates a fully static binary statically link using glibc that can be moved to any Linux platform with matching architecture. For example you can build on Debian 10 and run on Debian 8. This is basically an extended version of the `staticish` script. Mostly useful to port a modern build to an old platform.

~~~
ldd qbittorrent-nox
~~~

Gives this result:

~~~
not a dynamic executable
~~~

### Alpine Linux platform

`musl` - creates a fully static binary statically linked using `musl` instead of `glibc` that can be moved to any Linux platform with matching architecture. For example you can build on Alpine 3.11 and run on Debian 8. This is the how the `staticish` script should work on Debian but it's not a easy to build fully static. `musl` makes it really easy and just worked.

~~~
ldd qbittorrent-nox
~~~

Gives this result:

~~~
statically linked
~~~

## Details

Fully static builds were built and tested on:

**Debian 10 (buster)** amd64 and arm64

**Alpine linux 3.11** amd64

Debian 9 users follow this for more info when trying to build on this platform - https://github.com/qbittorrent/qBittorrent/issues/11882

## Script usage

Follow these instructions to install and use this build tool.

Executing the scripts will configure your build environment to make sure you can successfully build `qbittorrent-nox` but will not start the build process.

## Download

Use these commands via `ssh` on your Linux platform.

### Debian or Ubuntu 

#### staticish

~~~
wget -qO ~/qbittorrent-nox-staticish.sh https://git.io/JvLcs
chmod 700 ~/qbittorrent-nox-staticish.sh
~~~

To execute the script

~~~
~/qbittorrent-nox-staticish.sh
~~~

#### glibc

~~~
wget -qO ~/qbittorrent-nox-static-glibc.sh https://git.io/JvLcG
chmod 700 ~/qbittorrent-nox-static-glibc.sh
~~~

To execute the script

~~~
~/qbittorrent-nox-static-glibc.sh
~~~

#### Musl - Alpine linux

*Note: you need to install the bash shell on Alpine for this script to run.*

~~~
apk add bash
wget -qO ~/qbittorrent-nox-static-musl.sh https://git.io/JvLcZ
chmod 700 ~/qbittorrent-nox-static-musl.sh
~~~

To execute the script

~~~
~/qbittorrent-nox-static-musl.sh
~~~

## Build help

Once the script has successfully configured the platform you can execute the help argument to see how it works and what options you have available to you.

~~~
~/qbittorrent-nox-staticish.sh -h
~~~

## Build options

Install all modules and build `qbittorrent-nox` to the default build directory.

~~~
~/qbittorrent-nox-staticish.sh all
~~~

Install a specific module.

~~~
~/qbittorrent-nox-static.sh module
~~~

Supported modules

~~~
bison (qbittorrent-nox-static-glibc.sh only)
gawk (qbittorrent-nox-static-glibc.sh only)
zlib
icu
openssl
boost_build
boost
qtbase
qttools
libtorrent
glibc (qbittorrent-nox-static-glibc.sh only)
qbittorrent
~~~

By default the script will build to a hard coded path in the script `$install_dir` as to avoid installing files to a server and causing conflicts.

~~~
$HOME/qbittorrent-build
~~~

You can modify this dynamically with the `-b` argument

~~~
~/qbittorrent-nox-static.sh all -b "/usr/local"
~~~

### Installation

Once the script has successfully built `qbittorrent-nox` you can install it using this command:

~~~
~/qbittorrent-nox-static.sh install
~~~

*Note: If you built to a custom directory you will need to specify this to the install command using the `-b` argument.*

~~~
~/qbittorrent-nox-static.sh install -b "/path/to/built/binary"
~~~

The default installation path is determined by type of user executing the script.

**Root** - Built to - `$HOME/qbittorrent-build`

**Root** - Optionally installed to `/usr/local`

*Note: A local user still requires the core dependencies are installed to proceed.*

**Local user** - Built to - `$HOME/qbittorrent-build`

**Local user** - Optionally installed to `$HOME/bin`

## Download and install static builds

Build settings

*qBittorrent 4.2.1 was built with the following libraries:*

~~~
Qt: 5.14.0
Libtorrent: 1.2.3.0
Boost: 1.72.0
OpenSSL: 1.1.1d
zlib: 1.2.11
~~~

### glibc static

amd64

~~~
mkdir -p ~/bin && source ~/.profile
wget -qO ~/bin/qbittorrent-nox https://git.io/JvLcC
chmod 700 ~/bin/qbittorrent-nox
~~~

arm64:

~~~
mkdir -p ~/bin && source ~/.profile
wget -qO ~/bin/qbittorrent-nox https://git.io/JvLcW
chmod 700 ~/bin/qbittorrent-nox
~~~

Now you just run it and enjoy!

~~~
~/bin/qbittorrent-nox
~~~

### musl static

amd64:

~~~
mkdir -p ~/bin && source ~/.profile
wget -qO ~/bin/qbittorrent-nox https://git.io/JvLc0
chmod 700 ~/bin/qbittorrent-nox
~~~

arm64

~~~
none available yet
~~~

Now you just run it and enjoy!

~~~
~/bin/qbittorrent-nox
~~~

## Credits

Inspired by these gists

https://gist.github.com/notsure2