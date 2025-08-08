# Bash Scripting - All repos

- use $BASH_SOURCE instead of $0
- don't use uppercase variables for general scripting. Only use them for docker specific environment settings
- avoid set -euo pipefail - instead focus on thorough testing, validation and error handling.
- ideally error handling should be considered holistically but per function is acceptable.
- changes and recommendations should be simple, modular, focused on the requirement of the prompt.
- never make generalized changes that are not specifically required for the prompt.
- don't over complicated the solution or pollute it with noisy or complex solutions.
- Always makes changes in stages, a modular approach.
- use Google style guide for formatting of bash scripts - https://google.github.io/styleguide/shellguide.html
- Always use `#!/bin/bash` as the shebang.
- Use `printf '%s'` for printing strings and `printf '%b'` for escape sequences. **Avoid using `echo`.**
- Comment code to explain changes and logic.
- always prefer readability of code over complex one lines. Unless that foramt is promoted by the style guide.
- For Bash/shell questions, consult [mywiki.wooledge.org](https://mywiki.wooledge.org) or [BashFAQ](https://mywiki.wooledge.org/BashFAQ) first. **Provide a source link when possible.**

# GitHub Workflows - All repos

- In reusable workflows, jobs that use outputs from other jobs **must** include those jobs in their `needs` section to avoid null variables.
- Do not use outdated GitHub Actions in workflow code. Always check the version recommended is the current version
- The `gh` CLI cannot get the ID of a workflow it started with `gh run workflow`; you must list runs after and extract the ID.

# If repo = *-musl-cross-make
GCC / Binutils
- Use both `-static` and `--static` to create static toolchain binaries. Using `-static` alone can cause errors (e.g., missing POSIX threads).
- When working with `../config.mak`, always load options from both `../gcc-configure-options.md` and `../gcc-configure-options-recursive.md`.
- The binutils gold linker is deprecated. Use `ld=default` and `--disable-gold`.
- For fully static toolchains linked to musl:
    - Do **not** use `-flto` or `-fuse-linker-plugin` (LTO is not supported; plugins require dynamic loading).
    - Do **not** add any LTO settings.
- Only set linker options like `LDFLAGS` when linking, **not** when building libraries.
- GNU libtool redefines `-static`; to ensure static linking, use `--static` or `-Wl,-static` in `LDFLAGS` (possibly with `-static`).
- When building OpenSSL statically, do **not** use `openssl -static` (it disables threads, PIE, PIC). For `-static-pie` binaries with musl/Alpine, use the correct flags.
- Do **not** suggest glibc-only flags or glibcisms for musl toolchains.

# Debugging with qemu

- To debug with QEMU:
  Run `qemu -g <port> <binary>` (e.g., `qemu -g 1234 ./qbt-nox-static`), then connect with `gdb ./qbt-nox-static` in another terminal.

# If repo = * qbittorrent-nox-static

## qi.bash script

General features
- Always use `#!/bin/bash` as the shebang.
- this script is focused on being a simple installer that verifies installation and binaries.

basic check for supported os
- use source /etc/os-release
- if ID = alpine of debian or if the or if ID_LIKE=debian is debian like we can proceed.
- if not supported os exit with reason.

basic check for wget or curl, default to curl if present.
- if no tools exit with reason.
- wget or curl must have, curl default if present but use wget if there.
- check if gh cli is available to use but no required.

basic check of which arch using
- alpine use apk --print-arch
- debian like use dpkg --print-architecture
- all arches are the same except armhf. on debian this is armv7 and alpine armv6
- if not valid arch exit with reason.

create download function based on arch checks.
- configure download url based on arch.
- creates sha256 of download.

gh cli function
- if gh cli exists and is usable use it to very the binaries downloaded
- if gh attestation verify <INSTALL_PATH> --repo <REPO> 2> /dev/null; then ...

error handling
- there should be a error handling function to test commands exit the script with helpful explanations when a command or function fails.

ouputs
- there should be a function to handle printing outputs.
- It should handle [INFO] (blue) [WARNING] (yellow) [ERROR] (red) [SUCCESS] (Green) [FAILURE] (magenta)
- Use `printf '%s'` for printing strings and `printf '%b'` for escape sequences. **Avoid using `echo`.**
- this function will provide end user information understanding or troubleshooting script outcomes.
- it should be succinct unless there is an error or failure, then it should be verbose enough to help.
