---
title: Script Usage
hide_title: true
---

## First run expectations

Since the script is designed to be run in a temporary environment like docker or Github workflows, first thing the script does check the required critical dependencies are installed and attempt to install them if missing. Once this is done it will exit with some information printed to the terminal.

After this initial boot-strapping is completed it will not do anything else unless specifically told to do it.

:::tip Just use docker
The preferred and recommended build platform is Alpine Linux and the recommended method is via docker. It will just make things easier.
:::

:::caution Assumptions
The easiest way to progress if that I assume you have downloaded the script locally, as recommended in the previous section and that you have docker, [qemu and binmtfs](glossary/qemu) available to you.
:::

:::danger
It is not recommended to do this on a host you use regularly as it installs things you might not need or want.
:::

<Advanced>

:::tip
Dependencies are added dynamically based on the configuration. For example, `cmake` is not installed unless the build tool is configured to be `cmake`

Using the flag `-c` or the env `qbt_build_tool=cmake` will trigger these additional dependencies
:::
</Advanced>

<details className="custom-details">
  <summary>What to expect</summary>
  ![](@site/static/docs_images/script_usage/1.png)
</details>

When you are familiar with the script you can do anything you want with a one liner. It's pretty simple to use.

## Host - execute script

To execute the script use this command:

```bash
chmod +x ~/qbt.sh # make it executable
```

```bash
~/qbt.sh
```

## Docker via SSH

<Tabs>

<TabItem value="Notes" label="Notes">

Some notes on the dockers method:

- We will use a subdirectory and not your `$HOME` directory as to avoid `.bashrc` and `.profile` conflicts.
- The subdirectory will be automatically created and named `qbt` by the use of `-v $HOME/qbt:/root`
- The finale default path will be `HOME/qbt` outside the docker container and `/root/qbt` inside it.
- We assume you have downloaded the script as described in the previous section.
- We use `-e "LANG=en_GB.UTF-8"` with Debian based images to avoid some errors.

</TabItem>

<TabItem value="Debian Linux" label="Debian">

:::note tags
You use `debian:bullseye` `debian:latest`
:::

```bash
docker run -it -w /root -e "LANG=en_GB.UTF-8" -v ~/qbt:/root debian:latest bash qbt.sh
```

All in one command:

```bash
docker run -it -w /root -e "LANG=en_GB.UTF-8" -v $HOME/qbt:/root debian:latest /bin/bash -c 'apt update && apt install -y curl && curl -sL git.io/qbstatic | bash -s all'
```

</TabItem>

<TabItem value="Ubuntu Linux" label="Ubuntu">

:::note tags
You use `ubuntu:focal` `ubuntu:jammy` `ubuntu:latest`
:::

To bootstrap the container:

```bash
docker run -it -w /root -e "LANG=en_GB.UTF-8" -v $HOME/qbt:/root ubuntu:latest /bin/bash -c 'apt update && apt install -y curl && bash'
```

All in one command:

```bash
docker run -it -w /root -e "LANG=en_GB.UTF-8" -v $HOME/qbt:/root ubuntu:latest /bin/bash -c 'apt update && apt install -y curl && curl -sL git.io/qbstatic | bash -s all'
```

</TabItem>

<TabItem value="Alpine Linux" label="Alpine">

:::note tags
You use `alpine:edge` `alpine:latest`
:::

To bootstrap the container:

```bash
docker run -it -w /root -v $HOME/qbt:/root alpine:edge /bin/ash -c 'apk update && apk add bash curl && bash'
```

All in one command:

```bash
docker run -it -w /root -v $HOME/qbt:/root alpine:edge /bin/ash -c 'apk update && apk add bash curl && curl -sL git.io/qbstatic | bash -s all'
```

</TabItem>
</Tabs>

<Advanced>

:::note
Please see the [switches and flags summary](./build-help?id=switches-and-flags-summarised) to see what options you can pass and how to use them
:::

You can modify the installation command by editing this part of the docker command.

```bash
bash -s all
```

For example, to use `ICU` using `-i`, `-c` to trigger cmake and in turn activate Qt6 and optimise for the system CPU using `-o`:

```bash
bash -s all -i -c -o
```

</Advanced>
