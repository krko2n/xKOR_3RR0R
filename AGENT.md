# AGENT.md - xKOR_3RR0R AI Context File

This file provides crucial context for AI assistants working on this codebase.

## What is this project?
xKOR_3RR0R is a cyberpunk-themed system dashboard for Linux (Electron/Node.js).
It operates in two modes:
1. **App Mode:** Runs on top of a desktop (`npm start`).
2. **OS Mode:** Replaces the Linux desktop (BIOS -> Plymouth -> custom Node.js PAM login -> Electron Xorg session). Targets Arch-based systems.

## Tech Stack
Electron, node-pty, systeminformation, Express, Vanilla JS/CSS, Bash.
No Python/Rust allowed. Strictly Linux/Arch environment.

## Known Bugs & Fixes Applied
1. **node-pty Electron ABI Crash:** Handled in `run.sh` via `electron-rebuild`.
2. **Missing Execute Flags:** Windows Git strips `+x`. Managed via `git update-index --chmod=+x`.
3. **os/login Dependencies:** Requires isolated `npm install`. Installer (`os/install.sh`) handles this now.
4. **systeminformation Native Binaries:** Requires proper `npm install` directly on the target Linux system, which is why `node_modules` MUST NOT be tracked in Git.

## Rules
- PowerShell scripts for fixing MUST use `@'...'@` for bash content.
- Use explicit LF line endings for bash files.
- Never track `node_modules` or local config secrets.