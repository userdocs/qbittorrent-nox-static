# Project Memory: qbittorrent-nox-static

This file serves as a persistent context log for AI assistants to understand the current state, recent decisions, and technical constraints of the repository.

## Project State
- **Focus**: Building and distributing high-performance, statically linked `qbittorrent-nox` binaries.
- **Current Milestone**: Harmonizing AI configurations and optimizing toolchain linking (LTO/mold).

## Key Technical Decisions
- **Toolchain**: Using `[OWNER]/musl-cross-make` which is dynamically linked and designed for LTO and the `mold` linker.
- **Static Linking**: Always use both `-static` and `--static` to ensure all dependencies (including POSIX threads) are correctly captured.
- **Linker Logic**:
    - Build Script (`qbt-nox-static.bash`) uses `qbt_linker_mold=yes` to handle flag generation.
    - Raw Toolchain requires `-fuse-ld=mold`.
- **Mindset**: "C-like" development—prioritize stability, explicit error handling, and minimal external dependencies.

## Recent Changes (2026-04-25)
- **AI Config Harmonization**:
    - Updated `CLAUDE.md`, `.github/copilot-instructions.md`, and created `.cursorrules`.
    - Stripped "fluffy personas" in favor of strict technical instructions.
    - Synchronized OS/Arch detection logic and toolchain linking rules across all AI tools.
- **Linker Clarifications**: Corrected the documentation to reflect that `gold` is disabled in the toolchain and that `mold` requires explicit activation via `-fuse-ld=mold`.

## Known Gotchas & Constraints
- **I/O**: Never use `echo`; always use `printf '%s'` or `printf '%b'`.
- **Variables**: Lowercase for script-local logic; UPPERCASE for exported ENV/Docker settings.
- **Arch Mapping**: `armhf` is `armv7` on Debian/Ubuntu but `armv6` on Alpine.
- **OS Detection**: Must `source /etc/os-release` and check `ID` or `ID_LIKE`.
- **LTO Wrappers**: For LTO, use `gcc-ar`, `gcc-nm`, and `gcc-ranlib` to ensure symbol table integrity.
- **Privacy**: Use `[OWNER]/[REPO]` placeholders in documentation to prevent leaking specific paths.

## Pending Tasks
- [ ] Monitor CI performance with LTO and mold enabled.
- [ ] Verify `qi.bash` installer behavior on all supported architectures.
