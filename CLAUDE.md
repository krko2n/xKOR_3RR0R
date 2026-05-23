# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Project Overview

**xKOR_3RR0R** is a fullscreen cyberpunk system dashboard for Linux with two operating modes:
- **App Mode**: Tauri window on existing desktop (`./install.sh --app`)
- **OS Mode**: Replaces entire desktop environment (`sudo ./install.sh --mode=os`)

**Tech Stack**: Tauri v2 (Rust backend) + vanilla JavaScript frontend, targeting Arch Linux.

**Version**: 2.1.0-beta.1 (May 2026)

**Key Features (v2.1.0)**:
- Professional installation system (multi-distro)
- Automatic crash diagnostics with git auto-commit
- Enhanced Hyprland launcher with PAM session support
- Comprehensive logging infrastructure
- Premium upgrade UI with version tracking

---

## Build & Run Commands

### Development
```bash
# Professional installer (recommended)
./install.sh                    # Auto-detect distro, deps, build
./install.sh --dev              # Debug build

# Quick dev mode (legacy)
bash run.sh
# or
npm run dev

# Build Rust backend only
cd src-tauri && cargo build --release
```

### Production
```bash
# App Mode installation
./install.sh

# OS Mode installation (Arch Linux, Hyprland/Wayland)
sudo ./install.sh --mode=os

# Diagnostic system setup
./diagnostics/install-diagnostics.sh

# Upgrade (with premium UI + auto-backup)
./upgrade.sh

# System health check
./xkor-doctor.sh
./xkor-doctor.sh --fix          # Auto-fix issues
```

### Diagnostics (v2.1.0+)
```bash
# View live logs
tail -f diagnostics/logs/compositor/*.log
journalctl -u xkor-login -f

# Check for crashes
ls -lt diagnostics/crashes/

# Manual crash capture
./diagnostics/crash-logger.sh crash "type" "message"

# Cleanup old logs (7+ days)
./diagnostics/crash-logger.sh cleanup

# ALWAYS before debugging:
git pull  # Get auto-committed crash reports
```

### Testing & Verification
```bash
# Run single test
cd src-tauri && cargo test <test_name>

# Run all tests
cd src-tauri && cargo test

# Check Rust code
cd src-tauri && cargo check
cd src-tauri && cargo clippy
```

---

## Architecture

### Tauri v2 IPC Communication
- Frontend: `window.__TAURI__.core.invoke(command, args)` → Rust backend
- Backend events: `window.__TAURI__.event.listen(event, callback)` ← Rust emits
- No WebSocket, no Node.js backend, no Electron

### Core Components

**Rust Backend** (`src-tauri/src/`)
- `lib.rs` — Tauri setup, background stats emitter (1s interval), IPC command registration
- `terminal/mod.rs` — PTY manager using `nix` crate (fork + posix_openpt + execvp bash)
- `commands/system.rs` — `authenticate`, `get_system_stats` (CPU/RAM via sysinfo 0.33)
- `commands/fs.rs` — filesystem operations (list, read, write, delete, rename)
- `commands/ai.rs` — `ai_query` (Ollama/OpenAI via reqwest), `web_fetch`
- `commands/terminal_cmd.rs` — `terminal_spawn`, `write`, `resize`, `kill`, `get_network_status`

**Frontend** (`src/`)
- `index.html` — main entry: login screen → boot animation → app UI
- `js/app.js` — Tauri IPC bridge, globals, `initApp()`
- `js/login.js` — login UI, invokes `authenticate`, dispatches `xkor-auth` event
- `js/boot.js` — boot sequence (kernel logs + glitch), waits for `xkor-auth`
- `js/terminal.js` — xterm.js instances (3 tabs), Tauri PTY backend
- `js/tabs.js` — F1-F7 mode switching, dynamic terminal tabs
- `js/ai.js` — F5 AI panel, invokes `ai_query`
- `js/graphs.js` — CPU/RAM/TEMP sparkline graphs (Canvas2D, 200-point circular buffers)
- `js/globe.js` — pseudosphere with threat zones (Canvas2D, 60fps rotation)
- `js/filemanager.js` — file explorer, invokes `fs_list`/`fs_read`/`fs_write`/`fs_delete`/`fs_rename`
- `js/keyboard.js` — on-screen QWERTY visualizer

**OS Mode** (`os/`)
- `login/login.js` — TTY login app (Node.js readline + PAM via `pamtester`)
- `login/start-login.sh` — launches login.js on TTY1
- `systemd/xkor-login.service` — replaces getty@tty1, runs start-login.sh
- `xorg/xkor-session.sh` — startx wrapper, sets DISPLAY/XAUTHORITY
- `loading/loading.sh` — glitch animation (~4s) between login → startx
- `plymount/xkor/` — Plymouth boot theme

---

## Critical Paths & Conventions

### Installation Path
**ALWAYS** `/opt/xkor_3rr0r` (lowercase, underscore). Never `/opt/xKOR_3RR0R`. Hardcoded in:
- `os/login/login.js`
- `os/login/start-login.sh`
- `os/xorg/xkor-session.sh`
- `os/systemd/xkor-login.service`

### Configuration Files
- `config/user.json` — App Mode credentials (plaintext: `{"username": "admin", "password": "admin"}`)
- `config/ai-endpoint.json` — AI backend URL + model (default: Ollama localhost)

### Version Files (Semantic Versioning)
When bumping version, update ALL four:
1. `src-tauri/Cargo.toml` — `version = "X.Y.Z"`
2. `package.json` — `"version": "X.Y.Z"`
3. `src-tauri/tauri.conf.json` — `"version": "X.Y.Z"`
4. `os/install.sh` — `Version: X.Y.Z` (header comment)

Current: `2.0.0-beta.1` (feature freeze after Tauri v2 migration + audit)

---

## Boot Sequence (OS Mode)

```
Power on → GRUB → Kernel → Plymouth (xkor theme)
  → systemd multi-user.target
  → xkor-login.service (conflicts getty@tty1)
    → /opt/xkor_3rr0r/os/login/start-login.sh
      → node login.js (TTY1 readline app)
        → ASCII banner + Username/Password prompts
        → pamtester login <user> authenticate
        → FAIL: exit(1) → systemd restarts → login again
        → OK: ./loading.sh (~4s glitch animation)
              → startx /opt/xkor_3rr0r/os/xorg/xkor-session.sh
                → cd /opt/xkor_3rr0r && exec npm start
                  → Tauri fullscreen
```

---

## PTY Terminal Implementation

**Rust PTY** (`src-tauri/src/terminal/mod.rs`):
- Uses `nix::pty::posix_openpt` + `fork()` + `execvp("bash", ["--login"])`
- Sessions stored in `HashMap<String, Session>` (key = terminal ID)
- Background thread per session reads master_fd, emits `terminal-output` events
- Shell: bash with `--login` flag (sources ~/.bashrc, ~/.bash_profile)
- Nonblocking I/O with EAGAIN retry (10ms sleep)

**Frontend xterm.js** (`src/js/terminal.js`):
- 3 terminal instances: `term1`, `term2`, `term3`
- Connects to Rust PTY via `invoke('terminal_spawn', {id, cols, rows})`
- Writes input via `invoke('terminal_write', {id, data})`
- Receives output via `listen('terminal-output', callback)`
- Theme: cyberpunk palette (`#0a0a0a` bg, `#00ff9f` fg)

---

## System Stats Pipeline

**Backend** (`src-tauri/src/lib.rs`):
- Background thread spawned in `.setup()` closure
- Loops every 1 second: `collect_stats()` → emit `system-stats` event
- Uses `sysinfo` crate v0.33 (CPU, RAM)
- Network stats disabled (sysinfo 0.33 API changed — TODO: implement with netlink)
- Temperature disabled (TODO: read `/sys/class/thermal/thermal_zone0/temp`)

**Frontend** (`src/js/graphs.js`):
- Listens for `system-stats` event
- 200-point circular buffers (CPU, RAM, NET, TEMP)
- Canvas2D sparklines with neon colors:
  - CPU: `#00ff9f`
  - RAM: `#00d4ff`
  - NET: `#ffaa00`
  - TEMP: `#ff0033`

---

## AI Integration

**Backend** (`src-tauri/src/commands/ai.rs`):
- `ai_query(model: String, prompt: String)` → reqwest POST to `config/ai-endpoint.json`
- Default: Ollama at `http://localhost:11434/api/generate` with model `llama3`
- Returns response text or "AI endpoint unreachable"

**Frontend** (`src/js/ai.js`):
- F5 toggles `#ai-panel` overlay
- Enter sends message via `invoke('ai_query', {model, prompt})`
- Messages appended to `#ai-messages` (user/assistant roles)

---

## File Manager

**Backend** (`src-tauri/src/commands/fs.rs`):
- `fs_list(path: String)` → Vec<{name, type: "dir"|"file"}>
- `fs_read(path: String)` → {content} or {error}
- `fs_write(path: String, content: String)` → {ok}
- `fs_delete(path: String)` → {ok}
- `fs_rename(old_path: String, new_path: String)` → {ok}

**No path sanitization or auth** — full filesystem access. Avoid exposing to untrusted users.

**Frontend** (`src/js/filemanager.js`):
- Tree navigation via `invoke('fs_list', {path})`
- Right-click context menu (copy, paste, delete, rename)
- Open file: sends `cat "path"\r` to active terminal

---

## Emergency Recovery (OS Mode)

Black screen or failed login:

```bash
# Switch to TTY
Ctrl + Alt + F2

# Log in, then disable xKOR
sudo systemctl disable xkor-login.service
sudo systemctl stop xkor-login.service

# Restore display manager
sudo systemctl enable --now sddm  # or gdm/lightdm
sudo reboot
```

**Hyprland users** (Wayland, no DM):
```bash
# Start Hyprland manually
xkor-hyprland

# or
source /etc/profile.d/xkor-hyprland.sh
Hyprland
```

Fix `dwindle:pseudotile` error:
```bash
# Edit config
vim ~/.config/hypr/hyprland.conf
# Remove lines with dwindle:pseudotile

# Reload
hyprctl reload
```

---

## Known Issues & Workarounds

### ✅ FIXED in v2.1.0: Hyprland Socket Initialization Crash
**Symptom**: "Couldn't uniqfd for .sock2", compositor crash on startup  
**Root Cause**: xkor-login.service had no PAM session → systemd-logind never created `/run/user/UID`  
**Fix**: Added `PAMName=login` to `os/systemd/xkor-login.service`  
**Status**: RESOLVED. If still occurs, check `diagnostics/crashes/` for auto-captured report.

### Network & Temperature Stats Disabled
- sysinfo 0.33 removed network API
- TODO: Implement via netlink or `/proc/net/dev` direct read
- Temperature: TODO read `/sys/class/thermal/thermal_zone0/temp`

### Electron Binary Missing (OS Mode)
- If "Electron failed to install correctly": run `os/xorg/xkor-session.sh` (auto-reinstalls)
- Or manually: `cd /opt/xkor_3rr0r && npm install electron --unsafe-perm`

### X Server "unable to open display :0"
- X must run under authenticated user, not root
- login.js uses `su -l <user> -c "startx ..."` to switch user
- Fallback: cleanup stale `/tmp/.X0-lock` before startx

### Hyprland `dwindle:pseudotile` Error
- Old Hyprland syntax, removed in newer versions
- Installer auto-fixes via sed: `/dwindle:pseudotile/d`
- Also removes `pseudotile = true` inside `dwindle { }` blocks

### Debugging Tips (v2.1.0+)
- Check crash reports: `cat diagnostics/crashes/*.log`
- Live logs: `tail -f diagnostics/logs/compositor/*.log`
- System journal: `journalctl -u xkor-login -e`
- Manual capture: `./diagnostics/crash-logger.sh crash "type" "msg"`
- **Always `git pull` before debugging** - crash reports auto-commit

---

## Color Palette

- Primary neon: `#00ff9f`
- Cyan accent: `#00d4ff`
- Net/warning: `#ffaa00`
- Temp/danger: `#ff0033`
- Background: `#0a0a0a`
- Panel bg: `#111111`
- Border: `#00ff9f`
- Font: Share Tech Mono (Google Fonts)

---

## Commit Conventions

- `feat:` — new feature
- `fix:` — bug fix
- `chore:` — maintenance, updates, cleanup (no functional change)
- `refactor:` — rewrite code without behavior change
- `docs:` — documentation
- `style:` — formatting, whitespace, rename (no logic)

**Version bumps**: Create separate commit `chore(release): bump version X.Y.Z → X.Y.(Z+1)` after main change.

**Always** `git pull --rebase origin main` before `git push`.

---

## Development Notes

- Prefer editing existing files over creating new ones
- No comments unless WHY is non-obvious (constraints, workarounds, subtle invariants)
- Test UI changes in browser before reporting complete
- Never use `git commit --amend` unless explicitly requested (creates new commit instead)
- Never skip hooks (`--no-verify`) or bypass signing unless user asks
- Check for unsafe syscalls in Rust PTY code (dup2, close return values)
- Frontend login fallback: always deny on backend failure (never auto-grant)

---

## Repository Structure (Key Files)

```
src-tauri/
  src/
    lib.rs                 — Tauri setup, background stats, command registration
    main.rs                — Entry point (calls lib::run())
    terminal/mod.rs        — PTY manager (nix fork + execvp)
    commands/
      system.rs            — authenticate, get_system_stats
      fs.rs                — fs_list, fs_read, fs_write, fs_delete, fs_rename
      ai.rs                — ai_query, web_fetch
      terminal_cmd.rs      — terminal_spawn, write, resize, kill
  Cargo.toml               — version, dependencies (tauri, sysinfo, nix, reqwest)
  tauri.conf.json          — fullscreen, kiosk, CSP, icon paths
  build.rs                 — icon generation (PNG RGBA)

src/
  index.html               — login → boot → app screens
  js/
    app.js                 — IPC bridge, initApp()
    login.js               — login UI, authenticate invoke
    boot.js                — boot sequence, xkor-auth listener
    terminal.js            — xterm.js + PTY backend
    tabs.js                — F1-F7 mode switching
    ai.js                  — F5 AI panel
    graphs.js              — CPU/RAM/TEMP sparklines
    globe.js               — 3D pseudosphere (60fps Canvas2D)
    filemanager.js         — file explorer
    keyboard.js            — on-screen QWERTY
  css/                     — 10 theme files (strict palette)

os/
  install.sh               — OS Mode installer (pacman, systemd, Plymouth)
  upgrade.sh               — pull + rebuild + deploy (no reboot)
  login/
    login.js               — TTY readline app (PAM via pamtester)
    start-login.sh         — launches login.js on TTY1
  systemd/
    xkor-login.service     — replaces getty@tty1
  xorg/
    xkor-session.sh        — startx wrapper
  loading/
    loading.sh             — glitch animation
  plymount/xkor/           — Plymouth boot theme

config/
  user.json                — App Mode credentials
  ai-endpoint.json         — AI backend URL + model
```
