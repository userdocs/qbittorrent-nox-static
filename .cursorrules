# Technical Rules for qbittorrent-nox-static

## Standards
- **Tone**: No pandering. Focus on the solution.
- **Context**: Check `MEMORY.md` for project state. **Update `MEMORY.md` after completing a significant task.**
- **Privacy**: No secrets, tokens, or personal info in docs. Use `[OWNER]/[REPO]` placeholders.
- **Shebang**: Always `#!/bin/bash`.
- **I/O**: Use `printf`, never `echo`.
- **Quoting**: Quote all variables.
- **Reliability**: Explicit error checks. Avoid global `set -e`.
- **Naming**: Lowercase variables for script logic; UPPERCASE for ENV vars.

## Repo-Specific
- **LTO & Linker**:
  - `userdocs/musl-cross-make` supports LTO (`-flto`) and `mold`.
  - **Script**: Use `qbt_linker_mold=yes`.
  - **Toolchain**: Use `-fuse-ld=mold`.
- **Detection**: `source /etc/os-release`. Alpine `apk --print-arch`, Debian `dpkg --print-architecture`.
- **Linking**: Use both `-static` and `--static`. Set LDFLAGS at link time.

## Workflows
- Always declare `needs` for job output access.
- Use `gh run watch` to track triggered runs.

---

Focus on secure, robust, and efficient code. Refer to https://mywiki.wooledge.org for Bash best practices.
