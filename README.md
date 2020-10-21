# qbittorrent-nox-static

There are two platform specific bash scripts that will do three main things on their respective platform:

**1:** Update the system and install the core build dependencies - Requires root privileges if dependencies are not present.

**2:** Install and build the `qbittorrent-nox` specific dependencies locally with no special privileges required.

**3:** Build a fully static and portable `qbittorrent-nox` binary which automatically uses the latest version of all supported dependencies.

Here is an example build profile:

```
qBittorrent 4.2.5 was built with the following libraries:

Qt: 5.15.1
Libtorrent: 1.2.10.0
Boost: 1.74.0
OpenSSL: 1.1.1h
zlib: 1.2.11
```

Typically the script is deployed on a freshly created VPS but long as the system meets the core dependencies requirements tested for by the script, the script can be run as a local user.

See here for binaries I have built and how to install them - [Downloads](https://github.com/userdocs/qbittorrent-nox-static#download-and-install-static-builds)

## Debian or Ubuntu platforms

`glibc` - This script creates a fully static `qbittorrent-nox` binary using [libc](https://www.gnu.org/software/libc/).

The final result will show this when using `ldd`

```bash
ldd ~/qbittorrent-build/bin/qbittorrent-nox
```

Gives this result:

```bash
not a dynamic executable
```

## Alpine Linux platform

`musl` - This script creates a fully static `qbittorrent-nox` binary using [musl](https://wiki.musl-libc.org/).

The final result will show this when using `ldd`

```bash
ldd ~/qbittorrent-build/bin/qbittorrent-nox
```

Gives this result:

```bash
statically linked
```

## Script information

Fully static builds were built and tested on:

**Debian 10 (buster)** amd64

**Ubuntu 20.04 (focal)** amd64

**Alpine Linux 3.12** amd64

## Script usage

Follow these instructions to install and use this build tool.

*Executing the scripts will configure your build environment and may require a reboot to make sure you can successfully build `qbittorrent-nox` but will not start the build process until `all`  or a specific module name is passed as an argument to the script.*

Use these commands via `ssh` on your Linux platform.

### glibc - Debian or Ubuntu Linux

```bash
wget -qO ~/qbittorrent-nox-static-glibc.sh https://git.io/JvLcG
chmod 700 ~/qbittorrent-nox-static-glibc.sh
```

To execute the script

```bash
~/qbittorrent-nox-static-glibc.sh
```

### Musl - Alpine linux

*Note: you need to install the bash shell on Alpine for this script to run.*

```bash
apk add bash
```

Now download and execute the script.

```bash
wget -qO ~/qbittorrent-nox-static-musl.sh https://git.io/JvLcZ
chmod 700 ~/qbittorrent-nox-static-musl.sh
```

To execute the script

```bash
~/qbittorrent-nox-static-musl.sh
```

## Build help

Once the script has successfully configured the platform you can execute the help argument to see how it works and what options you have available to you.

```bash
~/qbittorrent-nox-staticish.sh -h
```

### Flags and arguments summarised

`all` - Will build all default modules.

These flags are available.

`-b` | `--build-directory` - This flag followed but a path will allow you to specify the build directory location. Relative directories are assumed to be in your `$HOME` and full paths used as typed. Applies to all modules.

`-n` | `--no-delete` -  After each module completes it removes the build folder and downloaded archives. This stops that in case you need to check something.  This is mostly for testing and can be generally ignored. Applies to all modules.

`-i` | `--icu` - This will install ICU to use with the build process. It creates a binary of around 50M compared to the default method with creates a 20M binary. Applies to the `icu` module.

`-m` | `--master` - For `libtorrent` this script will use the main branch for the version being used by the script. So instead of the release `1.2.10` we will use the branch `RC_1_2`. For `qbittorrent` the scrip will use the master branch. Applies to `libtorrent` and `qbitorrent` module.

`-ml` | `--master-libtorrent` - For `libtorrent` this script will use the main branch for the version being used by the script. Applies to the `libtorrent` module.

`-mq` | `--master-qbittorrent` - For `qbittorrent` the scrip will use the master branch. Applies to the `qbitorrent` module.

`-p` | `--proxy` - Allows you to specify a proxy to use will all external calls made by the script. Used by `curl` and `git`. Applies to all modules

### Build - default profile

Install all default modules and build `qbittorrent-nox` to the default build directory.

```bash
~/qbittorrent-nox-staticish.sh all
```

### Build - modules (optional)

```bash
~/qbittorrent-nox-static.sh module
```

Supported modules

```
bison (qbittorrent-nox-static-glibc.sh only)
gawk (qbittorrent-nox-static-glibc.sh only)
glibc (qbittorrent-nox-static-glibc.sh only)
zlib (default)
icu (optional on either platform)
openssl (default)
boost_build (default)
boost (default)
qtbase (default)
qttools (default)
libtorrent (default)
qbittorrent (default)
```

### Build - paths

By default the script will build to a hard coded path in the script `$install_dir` as to avoid installing files to a server and causing conflicts.

```bash
$HOME/qbittorrent-build
```

You can modify this dynamically with the `-b` argument

```bash
~/qbittorrent-nox-static.sh all -b "/usr/local"
```

### Installation

Once the script has successfully built `qbittorrent-nox` you can install it using this command:

```bash
~/qbittorrent-nox-static.sh install
```

*Note: If you built to a custom directory you will need to specify this to the install command using the `-b` argument.*

```bash
~/qbittorrent-nox-static.sh install -b "/path/to/built/binary"
```

The default installation path is determined by type of user executing the script.

**Root** - Built to - `$HOME/qbittorrent-build`

**Root** - Optionally installed to `/usr/local`

*Note: A local user still requires the core dependencies are installed to proceed.*

**Local user** - Built to - `$HOME/qbittorrent-build`

**Local user** - Optionally installed to `$HOME/bin`

## Download and install static builds

### Configuration

If you want to configure qBittorrent before you start it you this method

Create the default configuration directory.

```bash
mkdir -p ~/.config/qBittorrent
```

Create the configuration file.

```bash
touch ~/.config/qBittorrent/qBittorrent.conf
```

Edit the file

```bash
nano ~/.config/qBittorrent/qBittorrent.conf
```

Add this. Make sure to change your web ui port. 

```
[LegalNotice]
Accepted=true

[Preferences]
WebUI\Port=PORT
```

### glibc static

amd64

```bash
mkdir -p ~/bin && source ~/.profile
wget -qO ~/bin/qbittorrent-nox https://github.com/userdocs/qbittorrent-nox-static/releases/download/4.3.0.1.2.10/amd64-glibc-qbittorrent-nox
chmod 700 ~/bin/qbittorrent-nox
```

Now you just run it and enjoy!

```bash
~/bin/qbittorrent-nox
```

### musl static

amd64:

```
mkdir -p ~/bin && source ~/.profile
wget -qO ~/bin/qbittorrent-nox https://github.com/userdocs/qbittorrent-nox-static/releases/download/4.3.0.1.2.10/amd64-musl-qbittorrent-nox
chmod 700 ~/bin/qbittorrent-nox
```

Now you just run it and enjoy!

```
~/bin/qbittorrent-nox
```

Default login:

```
username: admin
password: adminadmin
```

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

### Second instance

When you simply call the binary it will look for it's configuration in `~/.config/qbittorrent`.

If you would like to run a second instance using another configuration you can do so like this

```bash
~/bin/qbittorrent-nox --configuration=NAME
```

This will create a new configuration directory using this suffix.

`~/.config/qbittorrent_NAME`

And you can now configure this instance separately.

### Nginx proxypass

```
location /qbittorrent/ {

    proxy_pass http://127.0.0.1:00000/;
    proxy_http_version      1.1;
    proxy_set_header        X-Forwarded-Host        $server_name:$server_port;
    proxy_hide_header       Referer;
    proxy_hide_header       Origin;
    proxy_set_header        Referer                 '';
    proxy_set_header        Origin                  '';

}
```

### Systemd service

Location for the systemd service file:

```
/etc/systemd/system/qbittorrent.service
```

Modify the path to the binary and your local username.

```
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
```

After any changes to the services reload using this command.

```bash
systemctl daemon-reload
```

Now you can enable the serice

```bash
systemctl enable --now qbittorrent.service
```

Now you can use these commands

```bash
systemctl stop qbittorrent
systemctl start qbittorrent
systemctl restart qbittorrent
```

### Systemd local user service

You can also use a local systemd service.

```
~/.config/systemd/user/qbittorrent.service
```

You can use this configuration with no modification required.

```
[Unit]
Description=qbittorrent
After=network-online.target

[Service]
Type=simple
ExecStart=%h/bin/qbittorrent-nox

[Install]
WantedBy=default.target
```

After any changes to the services reload using this command.

```bash
systemctl --user daemon-reload
```

Now you can enable the service

```bash
systemctl --user enable --now qbittorrent.service
```

Now you can use these commands

```bash
systemctl --user stop qbittorrent
systemctl --user start qbittorrent
systemctl --user restart qbittorrent
```

## Credits

Inspired by these gists

https://gist.github.com/notsure2