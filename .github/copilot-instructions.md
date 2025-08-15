# AI Coding Guide for This Repo

Purpose: Make AI contributions precise, minimal, and correct. Follow these rules strictly. Do not expand scope beyond the prompt.

## Bash scripting (applies to all repos)

Do
- Use `#!/bin/bash` as the shebang for Bash scripts.
- Use the `.bash` extension for Bash; use `.sh` only for POSIX-only scripts.
- Prefer `$BASH_SOURCE` over `$0` for script path detection.
- Use `printf '%s'` for plain strings and `printf '%b'` for escape sequences. Avoid `echo`.
- Keep changes simple, modular, and scoped to the exact prompt.
- Write readable code; add concise comments explaining intent and non-obvious logic.
- Handle errors explicitly (per function is acceptable); return helpful, actionable messages.
- Structure changes in small stages; keep functions focused.
- Format using Google’s Shell Style Guide: https://google.github.io/styleguide/shellguide.html
- For Bash references, consult: https://mywiki.wooledge.org and https://mywiki.wooledge.org/BashFAQ and include a source link when possible. Do not invent links.

Avoid
- Global “set -euo pipefail”; prefer targeted checks and explicit error handling.
- Uppercase variable names for general scripting (reserve UPPERCASE for Docker/env settings).
- Clever one-liners that harm clarity.
- Generalized or speculative changes not asked for in the prompt.
- Over-engineering; keep it stable, concise, and C-like in mindset.

Scope and behavior
- Only implement what the prompt requests.
- Keep solutions minimal and modular; do not add placeholders or future-proofing unless required.
- When giving Bash/shell answers, add a relevant wooledge link if helpful; never fabricate links.

## GitHub Workflows (all repos)

- In reusable workflows, any job that uses outputs from another job must declare that job in `needs` to avoid null outputs.
- Do not use outdated Actions. Check for current recommended versions before editing.
- The `gh` CLI cannot fetch the ID of a workflow run it just started via `gh run workflow`. List runs afterward and extract the ID.

## If repo name matches `*-musl-cross-make`

Toolchain specifics
- Use both `-static` and `--static` to produce static toolchain binaries. Using only `-static` can miss POSIX threads.
- When using `../config.mak`, always load options from both `../gcc-configure-options.md` and `../gcc-configure-options-recursive.md`.
- The binutils gold linker is deprecated. Use `ld=default` and `--disable-gold`.

Fully static toolchains with musl
- Do not use LTO: avoid `-flto` and `-fuse-linker-plugin`.
- Do not add any LTO-related settings.
- Only set linker options such as `LDFLAGS` at link time, not during library builds.
- GNU libtool redefines `-static`; to ensure static linking, use `--static` or `-Wl,-static` (optionally with `-static`) in `LDFLAGS`.
- For static OpenSSL: do not use `openssl -static` (it disables threads/PIE/PIC). For `-static-pie` with musl/Alpine, use the correct flags and approach.
- Do not use glibc-only flags or glibcisms for musl toolchains.

## Debugging with QEMU

- Start the target under QEMU with gdbstub, then attach with gdb:
  - `qemu -g <port> <binary>` (e.g., `qemu -g 1234 ./qbt-nox-static`)
  - In another terminal: `gdb ./qbt-nox-static` and `target remote :1234`

## If repo name matches `*qbittorrent-nox-static`

`qi.bash` script goals
- Simple installer that verifies installation and binaries.
- Shebang must be `#!/bin/bash`.

OS detection
- `source /etc/os-release`.
- Supported: `ID=alpine`, `ID=debian`, or `ID_LIKE` contains `debian`. Otherwise exit with a clear reason.

Transfer tools
- Prefer `curl` if present; use `wget` if present and `curl` is not; exit if neither is available.
- Detect presence of `gh` CLI and use it when available, but it is not required.

Architecture detection
- Alpine: `apk --print-arch`.
- Debian-like: `dpkg --print-architecture`.
- Architectures are the same across distros except `armhf`: Debian uses `armv7`, Alpine uses `armv6`.
- If architecture is not valid/supported, exit with a reason.

Download function
- Build the download URL from the detected architecture.
- Create and store the download’s SHA-256 sum.

Attestation (optional)
- When `gh` CLI is available and usable, verify downloaded binaries:
  - `gh attestation verify <INSTALL_PATH> --repo <REPO> 2> /dev/null`

Error handling
- Provide a helper that checks command exit codes and exits with a concise, helpful message on failure.

Output formatting
- Provide a print helper that supports:
  - `[INFO]` (blue), `[WARNING]` (yellow), `[ERROR]` (red), `[SUCCESS]` (green), `[FAILURE]` (magenta)
- Use `printf '%s'` and `printf '%b'`; do not use `echo`.
- Keep messages succinct. Be verbose only on errors to aid troubleshooting.

---

Meta for AI contributors
- Be conservative: do only what the prompt requests. No broad refactors.
- Prefer small, well-named functions and staged changes.
- Preserve existing public behavior and style unless the prompt requires changes.
- If something cannot be done with available context/tools, state why and propose the smallest viable alternative.
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
- Always use the extensions `bash` for bash script and `sh` only for posix shell scripts
- Use `printf '%s'` for printing strings and `printf '%b'` for escape sequences. **Avoid using `echo`.**
- Comment code to explain changes and logic.
- always prefer readability of code over complex one lines. Unless that foramt is promoted by the style guide.
- For Bash/shell questions, consult [mywiki.wooledge.org](https://mywiki.wooledge.org) or [BashFAQ](https://mywiki.wooledge.org/BashFAQ) first. **Provide a source link when possible.**
- Don't hallucinate <mywiki.wooledge.org> links in comments
- think like a c developer not a javascript developer. stable, concise, elegant and thoughtful. Not edgy and bleeding edge for the sake of it.
- when providing a solution to a prompt don't provide solutions outside the scope of the prompt nor add loads checks and fallbacks that quickly become redundant in following prompts.
- it makes me wast premium tokens making you fix the brken things you added or changed that were outside the scope of the prompt to begin with.
- provide changes specific to the prompt given.

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

## Astro and Astro starlight template for documentation

- Always use the mcp server https://mcp.docs.astro.build/mcp
- Always make sure imported mdx components start with an upper case letter.
