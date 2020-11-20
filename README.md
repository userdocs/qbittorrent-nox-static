# qbittorrent-nox-static

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/9817ad80d35c480aa9842b53001d55b0)](https://app.codacy.com/gh/userdocs/qbittorrent-nox-static?utm_source=github.com&utm_medium=referral&utm_content=userdocs/qbittorrent-nox-static&utm_campaign=Badge_Grade)

There are two platform specific bash scripts that will do three main things on their respective platform:

-   Update the system and install the core build dependencies - Requires root privileges if dependencies are not present.
-   Install and build the `qbittorrent-nox` specific dependencies locally with no special privileges required.
-   Build a fully static and portable `qbittorrent-nox` binary which automatically uses the latest version of all supported dependencies.

Here is an example build profile:

```none
qBittorrent 4.3.0.1 was built with the following libraries:

Qt: 5.15.1
Libtorrent: 1.2.11.0
Boost: 1.74.0
OpenSSL: 1.1.1h
zlib: 1.2.11
```

Typically the script is deployed on a freshly created VPS or docker but long as the system meets the core dependencies requirements tested for by the script, the script can be run as a local user.

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

**Note:** Executing the scripts will configure your build environment and may require a reboot to make sure you can successfully build `qbittorrent-nox` but will not start the build process until `all`  or a specific module name is passed as an argument to the script.

Use these commands via `ssh` on your Linux platform.

### glibc - Debian or Ubuntu Linux

User

```bash
wget -qO ~/qbittorrent-nox-static-glibc.sh https://git.io/gqbittorrent
chmod 700 ~/qbittorrent-nox-static-glibc.sh
```

To execute the script

```bash
~/qbittorrent-nox-static-glibc.sh
```

docker glibc

```bash
docker run -it -v $HOME/qb-build:/root debian:stable /bin/bash -c 'apt-get update && apt-get install -y curl && cd && curl -sL git.io/gqbittorrent | bash -s all'
```

**Note:** Please see the flag summary section below to see what options you can pass and how to use them

You can modify the installation command by editing this platform

```bash
bash -s all
```

For example

```bash
bash -s all -i -m
```

### Musl - Alpine Linux

**Note:** You need to install the bash shell on Alpine for this script to run.

```bash
apk add bash
```

Now download and execute the script.

```bash
wget -qO ~/qbittorrent-nox-static-musl.sh https://git.io/mqbittorrent
chmod 700 ~/qbittorrent-nox-static-musl.sh
```

To execute the script

```bash
~/qbittorrent-nox-static-musl.sh
```

docker musl

```bash
docker run -it -v $HOME/qb-build:/root alpine:latest /bin/ash -c 'apk update && apk add bash curl && cd && curl -sL git.io/mqbittorrent | bash -s all'
```

**Note:** Please see the flag summary section below to see what options you can pass and how to use them

You can modify the installation command by editing this platform

```bash
bash -s all
```

For example

```bash
bash -s all -i -m
```

## Build help

Once the script has successfully configured the platform you can execute the help argument to see how it works and what options you have available to you.

```bash
~/qbittorrent-nox-static-glibc.sh -h
~/qbittorrent-nox-static-musl.sh -h
```

### Flags and arguments summarised

Please use this feature to get help with a script option.

```bash
Here are a list of available options

 Use: -b  or --build-directory    Help: -h-b  or --help-build-directory
 Use: -n  or --no-delete          Help: -h-n  or --help-no-delete
 Use: -i  or --icu                Help: -h-i  or --help-icu
 Use: -m  or --master             Help: -h-m  or --help-master
 Use: -lm or --libtorrent-master  Help: -h-lm or --help-libtorrent-master
 Use: -lt or --libtorrent-tag     Help: -h-lt or --help-libtorrent-tag
 Use: -qm or --qbittorrent-master Help: -h-qm or --help-qbittorrent-master
 Use: -qt or --qbittorrent-tag    Help: -h-qt or --help-qbittorrent-tag
 Use: -p  or --proxy              Help: -h-p  or --help-proxy

Module specific help - flags are used with the modules listed here.

Use: all or module-name          Usage: ~/qbittorrent-nox-static-musl.sh all

 all         - Install all modules
 install     - optional Install the ~/qbittorrent-build/completed/qbittorrent-nox binary
 bison       - required Build bison
 gawk        - required Build gawk
 glibc       - required Build libc locally to statically link nss
 zlib        - required Build zlib locally
 icu         - optional Build ICU locally
 openssl     - required Build openssl locally
 boost       - required Download, extract and bootstrap the boost build files
 qtbase      - required Build qtbase locally
 qttools     - required Build qttools locally
 libtorrent  - required Build libtorrent locally with b2
 qbittorrent - required Build qbitorrent locally
```

### Build - default profile

Install all default modules and build `qbittorrent-nox` to the default build directory.

```bash
~/qbittorrent-nox-staticish.sh all
```

### Build - modules (optional and mostly for debugging and testing)

```bash
~/qbittorrent-nox-static.sh module
```

Supported modules

```bash
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

**Note:** This path is relative to the scripts location by default.

```bash
qbittorrent-build
```

You can modify this dynamically with the `-b` argument

```bash
./qbittorrent-nox-static.sh all -b "/usr/local"
```

### Installation

Once the script has successfully built `qbittorrent-nox` you can install it using this command:

```bash
./qbittorrent-nox-static.sh install
```

**Note:** If you built to a custom directory you will need to specify this to the install command using the `-b` argument.

```bash
./qbittorrent-nox-static.sh install -b "/path/to/built/binary"
```

The default installation path is determined by type of user executing the script.

**Root** - Built to - `qbittorrent-build`

**Root** - Optionally installed to `/usr/local`

**Note:** A local user still requires the core dependencies are installed to proceed.

**Local user** - Built to - `qbittorrent-build`

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

```ini
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

```bash
mkdir -p ~/bin && source ~/.profile
wget -qO ~/bin/qbittorrent-nox https://github.com/userdocs/qbittorrent-nox-static/releases/download/4.3.0.1.2.10/amd64-musl-qbittorrent-nox
chmod 700 ~/bin/qbittorrent-nox
```

Now you just run it and enjoy!

```bash
~/bin/qbittorrent-nox
```

Default login:

```bash
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

```bash
~/.config/qbittorrent_NAME
```

And you can now configure this instance separately.

### Nginx proxypass

```nginx
location /qbittorrent/ {
	proxy_pass http://127.0.0.1:8080/;
	proxy_http_version      1.1;
	proxy_set_header        X-Forwarded-Host        $http_host;
	http2_push_preload on; # Enable http2 push

	# The following directives effectively nullify Cross-site request forgery (CSRF)
	# protection mechanism in qBittorrent, only use them when you encountered connection problems.
	# You should consider disable "Enable Cross-site request forgery (CSRF) protection"
	# setting in qBittorrent instead of using these directives to tamper the headers.
	# The setting is located under "Options -> WebUI tab" in qBittorrent since v4.1.2.
	#proxy_hide_header       Referer;
	#proxy_hide_header       Origin;
	#proxy_set_header        Referer                 '';
	#proxy_set_header        Origin                  '';

	# Not needed since qBittorrent v4.1.0
	#add_header              X-Frame-Options         "SAMEORIGIN";
}
```

### Systemd service

Location for the systemd service file:

```bash
/etc/systemd/system/qbittorrent.service
```

Modify the path to the binary and your local username.

```ini
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

Now you can enable the service

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

```bash
~/.config/systemd/user/qbittorrent.service
```

You can use this configuration with no modification required.

```ini
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

<https://gist.github.com/notsure2>
