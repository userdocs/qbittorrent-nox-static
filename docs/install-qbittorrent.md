Once the script has successfully built `qbittorrent-nox` you can install the binary using this command:

```bash
bash ~/qbittorrent-nox-static.sh install
```

> [!warning|iconVisibility:hidden|labelVisibility:hidden|style:callout] If you built to a custom directory you will need to specify this to the install command using the `-b` argument.

```bash
bash ~/qbittorrent-nox-static.sh -b "/path/to/built/binary" install
```

The default installation path is determined by type of user executing the script.

<!-- tabs:start -->

<!-- tab: root -->

Built to - `qbt-build`

Optionally installed to `/usr/local/bin/qbittorrent-nox`

<!-- tab: user -->

Built to - `qbt-build`

Optionally installed to `$HOME/bin/qbittorrent-nox`

<!-- tabs:end -->

## GitHub Releases

Optionally you can just download the existing prebuilt binaries released using GitHub Actions.

<!-- tabs:start -->

<!-- tab: x86_64 -->

Without ICU

```bash
mkdir -p ~/bin && source ~/.profile
wget -qO ~/bin/qbittorrent-nox https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/x86_64-qbittorrent-nox
chmod 700 ~/bin/qbittorrent-nox
```

With ICU

```bash
mkdir -p ~/bin && source ~/.profile
wget -qO ~/bin/qbittorrent-nox https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/x86_64-icu-qbittorrent-nox
chmod 700 ~/bin/qbittorrent-nox
```

<!-- tab: aarch64 -->

Without ICU

```bash
mkdir -p ~/bin && source ~/.profile
wget -qO ~/bin/qbittorrent-nox https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/aarch64-qbittorrent-nox
chmod 700 ~/bin/qbittorrent-nox
```

With ICU

```bash
mkdir -p ~/bin && source ~/.profile
wget -qO ~/bin/qbittorrent-nox https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/aarch64-icu-qbittorrent-nox
chmod 700 ~/bin/qbittorrent-nox
```

<!-- tab: armv7 -->

Without ICU

```bash
mkdir -p ~/bin && source ~/.profile
wget -qO ~/bin/qbittorrent-nox https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/armv7-qbittorrent-nox
chmod 700 ~/bin/qbittorrent-nox
```

With ICU

```bash
mkdir -p ~/bin && source ~/.profile
wget -qO ~/bin/qbittorrent-nox https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/armv7-icu-qbittorrent-nox
chmod 700 ~/bin/qbittorrent-nox
```

<!-- tab: armhf -->

Without ICU

```bash
mkdir -p ~/bin && source ~/.profile
wget -qO ~/bin/qbittorrent-nox https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/armhf-qbittorrent-nox
chmod 700 ~/bin/qbittorrent-nox
```

With ICU

```bash
mkdir -p ~/bin && source ~/.profile
wget -qO ~/bin/qbittorrent-nox https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/armhf-icu-qbittorrent-nox
chmod 700 ~/bin/qbittorrent-nox
```

<!-- tabs:end -->

## Configuring qbittorrent

If you want to configure qBittorrent before you start it use this method:

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

Default login:

```bash
username: admin
password: adminadmin
```

Some key start-up arguments to help you along. Using the command above with no arguments will loads the defaults or the settings defined in the `~/.config/qBittorrent/qBittorrent.conf`

```none
Usage:
    ./qbittorrent-nox [options] [(<filename> | <url>)...]
Options:
    -v | --version             Display program version and exit
    -h | --help                Display this help message and exit
    --webui-port=<port>        Change the Web UI port
    -d | --daemon              Run in daemon-mode (background)
    --profile=<dir>            Store configuration files in <dir>
    --configuration=<name>     Store configuration files in directories
                               qBittorrent_<name>
    --relative-fastresume      Hack into libtorrent fastresume files and make
                               file paths relative to the profile directory
    files or URLs              Download the torrents passed by the user

Options when adding new torrents:
    --save-path=<path>         Torrent save path
    --add-paused=<true|false>  Add torrents as started or paused
    --skip-hash-check          Skip hash check
    --category=<name>          Assign torrents to category. If the category
                               doesn't exist, it will be created.
    --sequential               Download files in sequential order
    --first-and-last           Download first and last pieces first
    --skip-dialog=<true|false> Specify whether the "Add New Torrent" dialog
                               opens when adding a torrent.

Option values may be supplied via environment variables. For option named
'parameter-name', environment variable name is 'QBT_PARAMETER_NAME' (in upper
case, '-' replaced with '_'). To pass flag values, set the variable to '1' or
'TRUE'. For example, to disable the splash screen:
QBT_NO_SPLASH=1 ./qbittorrent-nox
Command line parameters take precedence over environment variables
```

## Starting qbittorrent

Now you just run it and enjoy!

```bash
~/bin/qbittorrent-nox
```

## Web ui

To get your external IP with the default qbittorrent command use this command:

```bash
echo $(wget -qO - icanhazip.com):8080
```

## Second instance

When you simply call the binary using `~/qbittorrent-nox ` it will look for it's configuration in `~/.config/qbittorrent`.

If you would like to run a second instance using another configuration you can do so like this

```bash
~/bin/qbittorrent-nox --configuration=NAME
```

This will create a new configuration directory using this suffix.

```bash
~/.config/qbittorrent_NAME
```

You will also need a custom nginx proxypass and systemd service.

And you can now configure this instance separately.
