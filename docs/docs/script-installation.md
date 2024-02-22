---
title: Script Installation
hide_title: true
---

:::tip Guide mode toggle
This documentation has a toggle in the nav menu to switch between a Basic and Advanced mode. In basic mode you'll see a version of the guide that assumes you have 0 knowledge of this project and how to use it.

It will avoid complexity and deviation into advanced tangents that would otherwise be helpful to someone who is already familiar with how the project works.
:::

<details className="custom-details">
<summary>Things to consider</summary>

There are actually a variety of ways you can approach the download and usage of the script.

🟩 Recommend: Download the script to a directory then go to the next section on docker usage where you create a docker around the local script. If you want to build stuff and test things you should download the script locally.

🟧 Optional: Download and bootstrap using a single docker command, which will be expanded on in detail in the next section. If you know exactly what you want to do you can simply make a one liner command to build the binary with no interaction required.

🟥 Not recommended: Download and run on the host. Dependencies like Qt have too many checks for system libs and not all are manageable to make sure the build is isolated from the host. It can work but most likely Qt will break stuff linking to things we don't want.

Toggle the Basic guide to Advanced to see the exampled in the next section.

</details>

For Alpine specifically, you need may to install bash to use this script.

```shell
apk add bash
```

### Install using a terminal

```shell
wget -qO ~/qbt.sh git.io/qbstatic
```

```shell
curl -sLo ~/qbt.sh git.io/qbstatic
```

<Advanced>

## Installation one liners using Docker

<Tabs>
<TabItem value="Docker notes" label="🔹Notes" default>

Some notes on the dockers method:

- We will use a subdirectory and not your `$HOME` directory as to avoid `.bashrc` and `.profile` conflicts.
- The subdirectory will be automatically created and named `qbt` by the use of `-v ~/qbt:/root`
- The finale default path will be `HOME/qbt` outside the docker container and `/root/qbt` inside it.

</TabItem>

<TabItem value="Debian Linux" label="🔹debian">

:::note tags
You use `debian:bullseye` `debian:latest`

:::

To bootstrap the container and run it:

```shell
docker run -it -w /root -e "LANG=en_GB.UTF-8" -v ~/qbt:/root debian:latest /bin/bash -c 'apt update && apt install -y curl && curl -sLo ~/qbt.sh git.io/qbstatic && bash'
```

Alternatively, to bootstrap a container named `qbtstatic` and it and leave it running in the background for reuse using `-d` :

```shell
docker run --name qbtstatic -it -d -w /root -e "LANG=en_GB.UTF-8" -v ~/qbt:/root debian:latest /bin/bash -c 'apt update && apt install -y curl && curl -sLo ~/qbt.sh git.io/qbstatic'
```

### Build one liners using Docker

You can also provide options or environment variables to the script in the one liner commands to do it all in one go.

</TabItem>
<TabItem value="Ubuntu Linux" label="🔹ubuntu" default>

:::note tags
You use `ubuntu:focal` `ubuntu:jammy` `ubuntu:latest`

:::

```shell
docker run -it -w /root -e "LANG=en_GB.UTF-8" -v ~/qbt:/root ubuntu:latest /bin/bash -c 'apt update && apt install -y curl && curl -sLo ~/qbt.sh git.io/qbstatic && bash'
```

Alternatively, to bootstrap a container named `qbtstatic` and it and leave it running in the background for reuse using `-d` :

```shell
docker run --name qbtstatic -it -d -w /root -e "LANG=en_GB.UTF-8" -v ~/qbt:/root ubuntu:latest /bin/bash -c 'apt update && apt install -y curl && curl -sLo ~/qbt.sh git.io/qbstatic'
```

</TabItem>
<TabItem value="Alpine linux" label="🔹alpine">

:::note tags
You use `alpine:edge` `alpine:latest`

:::

```shell
docker run -it -w /root -v ~/qbt:/root alpine:edge /bin/ash -c 'apk update && apk add bash curl && curl -sLo ~/qbt.sh git.io/qbstatic && bash'
```

All in one command:

```shell
docker run --name qbtstatic -it -w /root -v ~/qbt:/root alpine:edge /bin/ash -c 'apk update && apk add bash curl && curl -sLo ~/qbt.sh git.io/qbstatic'
```

</TabItem>
</Tabs>

</Advanced>
