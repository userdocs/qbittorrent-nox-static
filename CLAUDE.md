# Technical Guidelines for qbittorrent-nox-static

## Interaction Standards
- **No Pandering**: Never use phrases like "You're absolutely right" or "Great point".
- **Context Awareness**: Always check `MEMORY.md` for the latest project state. **Update `MEMORY.md` after completing any significant task or architectural change.**
- **Code-First**: Focus strictly on the problem, solution, and outcome.
- **Minimalism**: Only implement what is requested. No broad refactors or placeholders.
- **Privacy & Sanitization**: Never include secrets, tokens, local file paths (outside the workspace), private URLs, or identifiable personal information in `MEMORY.md` or other documentation. Use placeholders like `[OWNER]/[REPO]` if necessary.

## Bash Scripting Standards
- **Environment**: Target is Bash 4.x+ on Linux (Alpine, Debian/Ubuntu).
- **Shebang**: Always use `#!/bin/bash`.
- **Extension**: `.bash` for Bash scripts; `.sh` for POSIX-only.
- **Variables**: Always quote variables (`"$var"`). Use lowercase for script-local variables; UPPERCASE for exported ENV/Docker settings.
- **Pathing**: Use `$BASH_SOURCE` over `$0` for script path detection.
- **I/O**: Use `printf '%s'` or `printf '%b'`. **Never use `echo`**.
- **Formatting**: Adhere to [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html).
- **Tools**: Use `shfmt -s -bn -ci -sr -i 0` for formatting.
- **Logic**: Use advanced Bash features (associative arrays, parameter expansion) where appropriate for robustness.
- **Error Handling**: Explicitly check exit codes per function. Avoid global `set -e`.
- **Documentation**: Reference [mywiki.wooledge.org](https://mywiki.wooledge.org) and [BashFAQ](https://mywiki.wooledge.org/BashFAQ) for complex logic.

## Repository-Specific Rules

### Core Build Scripts
- **`qbt-nox-static.bash`**: Uses complex associative arrays (`declare -A`) and semver logic. Maintain this complexity; do not simplify.
- **`qi.bash`**: Installer focused on OS/Arch detection and binary verification.

### Toolchain & Static Linking
- **Linking**: Use both `-static` and `--static` for toolchain binaries.
- **LTO & Linker**:
  - `userdocs/musl-cross-make` is dynamically linked and supports LTO (`-flto`) and `mold`.
  - **Build Script**: Use `qbt_linker_mold=yes` flag.
  - **Raw Toolchain**: Use `-fuse-ld=mold`.
- **LDFLAGS**: Apply linker options only at final link time.
- **OpenSSL**: Do not use `openssl -static` (it disables threads). Use correct flags for `-static-pie` on musl.

### OS & Architecture
- **Detection**: `source /etc/os-release`.
- **Architectures**: Note `armhf` differences (Debian armv7 vs Alpine armv6).

## GitHub Workflows
- **Dependencies**: Job outputs require explicit `needs` declarations.
- **CLI**: Use `gh run list` and `gh run watch` to track workflow runs.

---

# Claude Code Configuration

## bash-expert
**Description:** Technical expert for Bash scripting and Unix/Linux systems.
**Prompt:** You are a technical expert in Bash scripting. Follow the guidelines in CLAUDE.md exactly. Prioritize secure, robust, and efficient code using proper quoting, error handling, and the "do one thing well" philosophy. Never use echo—always use printf.
