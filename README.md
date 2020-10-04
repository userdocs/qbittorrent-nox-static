# qbittorrent-nox-static

A build script for `qBittorent-nox` to create a partially or fully static automatically using the current releases of the main dependencies when the script is executed.

See here for binaries I have built and how to install them - [Downloads](https://github.com/userdocs/qbittorrent-nox-static#download-and-install-static-builds)

## Info

There are 2 scripts for 2 platforms.

### Debian or Ubuntu platforms

`glibc` - This create a fully static `qbittorrent-nox` binary using [libc](https://www.gnu.org/software/libc/). This is that standard on Debian Linux.

The final result will show this when using `ldd`

~~~bash
ldd ~/qbittorrent-build/bin/qbittorrent-nox
~~~

Gives this result:

~~~bash
not a dynamic executable
~~~

### Alpine Linux platform

`musl` - This create a fully static `qbittorrent-nox` binary using [musl](https://wiki.musl-libc.org/). This is that standard on Alpine Linux.

The final result will show this when using `ldd`

~~~bash
ldd ~/qbittorrent-build/bin/qbittorrent-nox
~~~

Gives this result:

~~~bash
statically linked
~~~

## Details

Fully static builds were built and tested on:

**Debian 10 (buster)** amd64

**Ubuntu 20.04 (focal)** amd64

**Alpine Linux 3.12** amd64

## Script usage

Follow these instructions to install and use this build tool.

*Executing the scripts will configure your build environment and may require a reboot to make sure you can successfully build `qbittorrent-nox` but will not start the build process until `all`  or a specific module name is passed as an argument to the script.*

## Download

Use these commands via `ssh` on your Linux platform.

### Debian or Ubuntu 

#### glibc - Debian or Ubuntu Linux

~~~bash
wget -qO ~/qbittorrent-nox-static-glibc.sh https://git.io/JvLcG
chmod 700 ~/qbittorrent-nox-static-glibc.sh
~~~

To execute the script

~~~bash
~/qbittorrent-nox-static-glibc.sh
~~~

#### Musl - Alpine linux

*Note: you need to install the bash shell on Alpine for this script to run.*

~~~bash
apk add bash
wget -qO ~/qbittorrent-nox-static-musl.sh https://git.io/JvLcZ
chmod 700 ~/qbittorrent-nox-static-musl.sh
~~~

To execute the script

~~~bash
~/qbittorrent-nox-static-musl.sh
~~~

## Build help

Once the script has successfully configured the platform you can execute the help argument to see how it works and what options you have available to you.

~~~bash
~/qbittorrent-nox-staticish.sh -h
~~~

These flags are available.

`-b` | `--build-directory` - This flag followed but a path will allow you to specify the build directory location. Relative directories are assumed to be in your `$HOME` and full paths used as typed.

`-n` | `--no-delete` -  After each module completes it removes the build folder and downloaded archives. This stops that in case you need to check something.  This is mostly for testing and can be generally ignored.

`-i` | `--icu` - This will install ICU to use with the build process. It creates a binary of around 50M compared to the default method with creates a 20M binary.

`-m` | `--master` - For `libtorrent` this script will use the main branch for the version being used by the script. So instead of the release `1.2.10` we will use the branch `RC_1_2`. For `qbittorrent` the scrip will use the master branch.

`-p` | `--proxy` - Allows you to specify a proxy to use will all external calls made by the script. Used by `curl` and `git`.

`-ish` | `--staticish` - `glibc` only - will create a statically linked binary with the exclusion of `libc`. Faster build time but less portable. This is mostly for testing and can be generally ignored.

## Build options

Install all modules and build `qbittorrent-nox` to the default build directory.

~~~bash
~/qbittorrent-nox-staticish.sh all
~~~

Install a specific module.

~~~bash
~/qbittorrent-nox-static.sh module
~~~

Supported modules

~~~
bison (qbittorrent-nox-static-glibc.sh only)
gawk (qbittorrent-nox-static-glibc.sh only)
glibc (qbittorrent-nox-static-glibc.sh only)
zlib
icu (optional)
openssl
boost_build
boost
qtbase
qttools
libtorrent
qbittorrent
~~~

By default the script will build to a hard coded path in the script `$install_dir` as to avoid installing files to a server and causing conflicts.

~~~bash
$HOME/qbittorrent-build
~~~

You can modify this dynamically with the `-b` argument

~~~bash
~/qbittorrent-nox-static.sh all -b "/usr/local"
~~~

### Installation

Once the script has successfully built `qbittorrent-nox` you can install it using this command:

~~~bash
~/qbittorrent-nox-static.sh install
~~~

*Note: If you built to a custom directory you will need to specify this to the install command using the `-b` argument.*

~~~bash
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

*qBittorrent 4.2.5 was built with the following libraries:*

~~~
Qt: 5.15.0
Libtorrent: 1.2.10.0
Boost: 1.74.0
OpenSSL: 1.1.1h
zlib: 1.2.11
~~~

### Configuration

If you want to configure qBittorrent before you start it you this method

Create the default configuration directory.

~~~bash
mkdir -p ~/.config/qBittorrent
~~~

Create the configuration file.

~~~bash
touch ~/.config/qBittorrent/qBittorrent.conf
~~~

Edit the file

~~~bash
nano ~/.config/qBittorrent/qBittorrent.conf
~~~

Add this. Make sure to change your web ui port. 

~~~
[LegalNotice]
Accepted=true

[Preferences]
WebUI\Port=PORT
~~~

Save and exit. Now download and run `qbittorrent-nox`.

### glibc static

amd64

~~~bash
mkdir -p ~/bin && source ~/.profile
wget -qO ~/bin/qbittorrent-nox https://github.com/userdocs/qbittorrent-nox-static/releases/download/4.2.5.1.2.10/amd64-glibc-qbittorrent-nox
chmod 700 ~/bin/qbittorrent-nox
~~~

Now you just run it and enjoy!

~~~bash
~/bin/qbittorrent-nox
~~~

### musl static

amd64:

~~~
mkdir -p ~/bin && source ~/.profile
wget -qO ~/bin/qbittorrent-nox https://github.com/userdocs/qbittorrent-nox-static/releases/download/4.2.5.1.2.10/amd64-musl-qbittorrent-nox
chmod 700 ~/bin/qbittorrent-nox
~~~

Now you just run it and enjoy!

~~~
~/bin/qbittorrent-nox
~~~

Default login:

~~~
username: admin
password: adminadmin
~~~

Some key start-up arguments to help you along. Using the command above with no arguments will loads the defaults or the settings define in the `~/.config/qBittorrent/qBittorrent.conf`

```bash
Options:
    -v | --version             Display program version and exit
    -h | --help                Display this help message and exit
    --webui-port=<port>        Change the Web UI port
    -d | --daemon              Run in daemon-mode (background)
    --profile=<dir>            Store configuration files in <dir>
    --configuration=<name>     Store configuration files in directories
                               qBittorrent_<name>
```

### Nginx proxypass

~~~
location /qbittorrent/ {

    proxy_pass http://127.0.0.1:00000/;
    proxy_http_version      1.1;
    proxy_set_header        X-Forwarded-Host        $server_name:$server_port;
    proxy_hide_header       Referer;
    proxy_hide_header       Origin;
    proxy_set_header        Referer                 '';
    proxy_set_header        Origin                  '';

}
~~~

### Systemd service

Location for the systemd service file:

~~~
/etc/systemd/system/qbittorrent.service
~~~

Modify the path to the binary and your local username.

~~~
[Unit]

Description=qbittorrent-nox
Wants=network-online.target
After=network-online.target nss-lookup.target

[Service]

User=username
Group=username

Type=exec
WorkingDirectory=/home/username

ExecStart=/home/username/bin/qbittorrent-nox
KillMode=control-group
Restart=always
RestartSec=5
TimeoutStopSec=infinity

[Install]
WantedBy=multi-user.target
~~~

After any changes to the services reload using this command.

~~~bash
systemctl daemon-reload
~~~

Now you can enable the serice

~~~bash
systemctl enable --now qbittorrent.service
~~~

Now you can use these commands

~~~bash
service qbittorrent stop
service qbittorrent start
service qbittorrent restart
~~~

## Credits

Inspired by these gists

https://gist.github.com/notsure2