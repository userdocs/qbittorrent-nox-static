## Pre installation

> [!warning|iconVisibility:hidden|labelVisibility:hidden] Executing just the script will only configure your build environment and may require a reboot to make sure you can successfully build `qbittorrent-nox`
>
> The build process will not start until `all` or a specific module name is provided to the script as a positional parameter.

> [!TIP|iconVisibility:hidden|labelVisibility:hidden] The preferred and recommended build platform is Alpine Linux and the recommended method is via docker.

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

If you need to install the dependencies and you have `sudo` privileges then do this:

> [!WARNING|iconVisibility:hidden|labelVisibility:hidden] You only need to do this once as root to install the dependencies.

```bash
sudo bash ~/qbittorrent-nox-static.sh
```

> [!TIP|iconVisibility:hidden|labelVisibility:hidden] Using certain switches can add dependencies like `-c` for cmake. So you may need to escalate your privileges again.

## Docker via SSH

Some notes on the dockers method:

- We will use a subdirectory and not your `$HOME` directory as to avoid `.bashrc` and `.profile` conflicts.
- The subdirectory will be automatically created and named `qbt` by the use of `-v $HOME/qbt:/root`
- The finale default path will be `HOME/qbt` outside the docker container and `/root/qbt` inside it.

> [!TIP|iconVisibility:hidden|labelVisibility:hidden] build envs can be passed to the docker using `-e` . Such as `-e qbt_cross_name=aarch64`

<!-- tabs:start -->

<!-- tab: Debian -->

> [!TIP|iconVisibility:hidden|labelVisibility:hidden] You use `debian:buster` `debian:bullseye`  `debian:latest`

To bootstrap the container:

```bash
docker run -it -w /root -e "LANG=en_GB.UTF-8" -v $HOME/qbt:/root debian:latest /bin/bash -c 'apt update && apt install -y curl && bash'
```

All in one command:

```bash
docker run -it -w /root -e "LANG=en_GB.UTF-8" -v $HOME/qbt:/root debian:latest /bin/bash -c 'apt update && apt install -y curl && curl -sL git.io/qbstatic | bash -s all'
```

<!-- tab: Ubuntu -->

> [!TIP|iconVisibility:hidden|labelVisibility:hidden] You use `ubuntu:bionic` `ubuntu:focal` `ubuntu:hirsute` `ubuntu:latest`

To bootstrap the container:

```bash
docker run -it -w /root -e "LANG=en_GB.UTF-8" -v $HOME/qbt:/root ubuntu:latest /bin/bash -c 'apt update && apt install -y curl && bash'
```

All in one command:

```bash
docker run -it -w /root -e "LANG=en_GB.UTF-8" -v $HOME/qbt:/root ubuntu:latest /bin/bash -c 'apt update && apt install -y curl && curl -sL git.io/qbstatic | bash -s all'
```

<!-- tab: Alpine -->

> [!TIP|iconVisibility:hidden|labelVisibility:hidden] You use `alpine:edge` `alpine:latest`

To bootstrap the container:

```bash
docker run -it -w /root -v $HOME/qbt:/root alpine:edge /bin/ash -c 'apk update && apk add bash curl && bash'
```

All in one command:

```bash
docker run -it -w /root -v $HOME/qbt:/root alpine:edge /bin/ash -c 'apk update && apk add bash curl && curl -sL git.io/qbstatic | bash -s all'
```

<!-- tabs:end -->

> [!NOTE|iconVisibility:hidden|labelVisibility:hidden] Please see the [switches and flags summary](/build-help?id=switches-and-flags-summarised) to see what options you can pass and how to use them

You can modify the installation command by editing this part of the docker command.

```bash
bash -s all
```

For example, to use `ICU` using `-i`, `-c` to trigger cmake and in turn activate Qt6 and optimise for the system CPU using `-o`:

```bash
bash -s all -i -c -o
```

