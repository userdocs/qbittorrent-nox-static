## Pre installation

> [!warning|iconVisibility:hidden|labelVisibility:hidden] Executing just the script will only configure your build environment and may require a reboot to make sure you can successfully build `qbittorrent-nox`
>
> The build process will not start until `all` or a specific module name is provided to the script as a positional parameter.

## Using SSH
As a local user

```bash
wget -qO ~/qbittorrent-nox-static.sh https://git.io/qbstatic
```

For Alpine specifically, you need to install bash to use this script.

```bash
apk add bash
```

To execute the script use this command:

```bash
bash ~/qbittorrent-nox-static.sh
```

If you need to install the dependencies and you have sudo privileges then do this:

> [!WARNING|iconVisibility:hidden|labelVisibility:hidden] You only need to do this once as root to install the dependencies.

```bash
sudo bash ~/qbittorrent-nox-static.sh
```

## Docker via SSH

<!-- tabs:start -->

<!-- tab: Debian -->

```bash
docker run -it -v $HOME:/root debian:latest /bin/bash -c 'apt-get update && apt-get install -y curl && cd && curl -sL git.io/qbstatic | bash -s all'
```

<!-- tab: Ubuntu -->

```bash
docker run -it -v $HOME:/root ubuntu:latest /bin/bash -c 'apt-get update && apt-get install -y curl && cd && curl -sL git.io/qbstatic | bash -s all'
```

<!-- tab: Alpine -->

```bash
docker run -it -v $HOME:/root alpine:latest /bin/ash -c 'apk update && apk add bash curl && cd && curl -sL git.io/qbstatic | bash -s all'
```

<!-- tabs:end -->

> [!NOTE|iconVisibility:hidden|labelVisibility:hidden] Please see the [switches and flags summary](/build-help?id=switches-and-flags-summarised) to see what options you can pass and how to use them

You can modify the installation command by editing this part of the docker command.

```bash
bash -s all
```

For example, to use `ICU` using `-i` and optimise for the system CPU using `-o`:

```bash
bash -s all -i -o
```
