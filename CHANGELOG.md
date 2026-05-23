# xKOR_3RR0R Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.1.0-beta.1] - 2026-05-24

### 🔥 Critical Fix - Hyprland Compositor Crash

**Root Cause Identified and Resolved:**
- xkor-login.service had NO PAM session
- systemd-logind never created `/run/user/UID`
- Hyprland crashed with "Couldn't uniqfd for .sock2"
- **Fix**: Added `PAMName=login` to systemd service

### Added

#### Comprehensive Diagnostic System
- **Automatic crash logger** (`diagnostics/crash-logger.sh`)
  - Captures full system state on crash
  - Logs: kernel, memory, processes, sessions, environment, journal
  - Auto-commits crash reports to git
  - Structured reports: `diagnostics/crashes/YYYY-MM-DD_HH-MM-SS.log`

- **Enhanced Hyprland launcher** (`os/bin/start-hyprland`)
  - Pre-flight validation checks
  - Automatic stale socket cleanup
  - Runtime directory verification
  - Comprehensive logging to `diagnostics/logs/compositor/`
  - Graceful error handling with crash capture

- **Centralized logging infrastructure**
  - `diagnostics/logs/{compositor,runtime,install,upgrade,frontend,backend,terminal,system}`
  - All logs timestamped with rotation
  - Automatic 7-day log cleanup
  - Git tracks crashes/errors, ignores bulk logs

- **Diagnostic installer** (`diagnostics/install-diagnostics.sh`)
  - One-command setup for diagnostic system
  - Configures git to track crash reports
  - Updates systemd service with PAM support

#### Premium Upgrade System
- **Enhanced upgrade.sh** with professional UI
  - Full ASCII art xKOR_3RR0R banner
  - Version comparison display (old → new)
  - Animated braille spinner for compilation
  - Premium success banner with version info
  - Automatic backup before upgrade
  - Rollback on failure

- **Auto-versioning system** (`scripts/bump-version.sh`)
  - Automated version bumping across all files
  - Supports: patch, minor, major, pre, release
  - Updates 7 version files automatically
  - Creates git tags

### Changed

#### systemd Service Hardening
- Added `PAMName=login` - enables proper session initialization
- Added `SyslogIdentifier=xkor-os` - easy journalctl filtering
- Changed `Restart=on-failure` with 3s cooldown
- Added proper `User=` and `WorkingDirectory=` directives
- Changed target from `multi-user.target` to `graphical.target`

#### Installation System
- Multi-distro support (Debian, Ubuntu, Arch, Fedora, openSUSE, Alpine)
- Automatic package manager detection
- Professional CLI UI with color-coded output
- Comprehensive error handling and logging

### Fixed

- **Hyprland socket initialization** - PAM session now properly created
- **Runtime directory creation** - systemd-logind creates it automatically
- **Permission errors** - proper user context via PAM
- **Stale socket cleanup** - automatic on each startup
- **Boot sequence freeze** - script loading order and global function exposure
- **Login UI** - eDEX-UI inspired design with scanlines and CRT effects

### Documentation

- Updated `README.md` with diagnostic system, v2.1.0 features
- Updated `AGENT.md` with diagnostic workflow, PAM fix details
- Updated `CLAUDE.md` with new build commands, diagnostic tools
- Added `DEPLOYMENT.md` - comprehensive deployment guide
- Added `VERSION.md` - version management guide
- Added `CHANGELOG.md` - this file

### Deployment

**On Your System:**
```bash
cd /opt/xkor_3rr0r
git pull
./upgrade.sh
./diagnostics/install-diagnostics.sh
sudo reboot
```

**After Upgrade:**
- Clean Hyprland startup (no socket errors)
- Automatic crash capture if anything fails
- Git history of all crashes
- Comprehensive logs for debugging

---

## [2.0.2-beta.1] - 2026-05-23

### Fixed
- Boot sequence script loading order
- Login screen global function exposure
- Added debug logging throughout boot/login flow
- Added ESC key bypass for boot animation
- Added failsafe timeout for boot

### Changed
- Redesigned login screen with eDEX-UI aesthetic
- Added scanline and CRT flicker effects
- Improved input placeholders and keyboard hints

---

## [2.0.1-beta.1] - 2026-05-23

### Added
- Premium upgrade UI with ASCII art banner
- Version change display with box UI
- Animated spinner for long-running operations
- Auto-versioning script (`scripts/bump-version.sh`)

### Changed
- Enhanced upgrade script with progress indicators
- Professional success banner with version info
- Improved error handling in upgrade process

---

## [2.0.0-beta.1] - 2026-05-XX

### Added
- Professional installation system (multi-distro)
- Smart upgrade with automatic backup/rollback
- System diagnostics with auto-fix (`xkor-doctor.sh`)
- Safe uninstall with config preservation
- Modular frontend architecture
- Theme system with JSON configs
- 5-terminal orchestration
- Event-driven audio system
- Three.js WebGL globe renderer

### Changed
- Migrated from Electron to Tauri v2
- Replaced Node.js backend with Rust
- Replaced WebSocket IPC with Tauri invoke/events
- Replaced node-pty with native Rust PTY (nix crate)

---

## Version History Overview

| Version | Date | Major Changes |
|---------|------|---------------|
| 2.1.0-beta.1 | 2026-05-24 | Diagnostic system, PAM fix, premium upgrade |
| 2.0.2-beta.1 | 2026-05-23 | Boot sequence fixes, login redesign |
| 2.0.1-beta.1 | 2026-05-23 | Premium upgrade UI, auto-versioning |
| 2.0.0-beta.1 | 2026-05-XX | Tauri v2 migration, modular architecture |

---

## Migration Notes

### From v2.0.x to v2.1.0

**Breaking Changes:**
- None - fully backward compatible

**New Requirements:**
- PAM session support (already in systemd)
- Git for crash report auto-commit (optional but recommended)

**Upgrade Path:**
```bash
./upgrade.sh  # Automatic upgrade with backup
```

**What to Test:**
- Hyprland compositor startup (should not crash)
- Runtime directory creation (`ls -la /run/user/1000`)
- Crash logger (`./diagnostics/crash-logger.sh crash "test" "msg"`)
- Log rotation (`./diagnostics/crash-logger.sh cleanup`)

### From Electron to Tauri (v1.x to v2.0.0)

**Breaking Changes:**
- Complete architecture rewrite
- No backward compatibility with v1.x configs
- Must reinstall OS Mode

**Migration Path:**
- Backup user data
- Uninstall v1.x
- Fresh install v2.0.0+

---

## Deprecation Notices

### Deprecated in v2.1.0
- None

### Removed in v2.1.0
- Old TTY login system (`os/login/login.js`) - replaced by direct Hyprland launch

### Deprecated in v2.0.0
- Electron backend (`src/main.js`, `src/preload.js`)
- Node.js backend (`backend/server.js`, `backend/terminal/pty.js`)
- WebSocket IPC
- Express server

---

## Support

- **GitHub Issues**: https://github.com/krko2n/xKOR_3RR0R/issues
- **Crash Reports**: `diagnostics/crashes/` (auto-committed to git)
- **Documentation**: `DEPLOYMENT.md`, `README.md`, `CLAUDE.md`, `AGENT.md`

---

## Contributors

- **krko2n** - Creator and maintainer

---

## License

MIT License - See [LICENSE](LICENSE) file

---

[2.1.0-beta.1]: https://github.com/krko2n/xKOR_3RR0R/releases/tag/v2.1.0-beta.1
[2.0.2-beta.1]: https://github.com/krko2n/xKOR_3RR0R/releases/tag/v2.0.2-beta.1
[2.0.1-beta.1]: https://github.com/krko2n/xKOR_3RR0R/releases/tag/v2.0.1-beta.1
[2.0.0-beta.1]: https://github.com/krko2n/xKOR_3RR0R/releases/tag/v2.0.0-beta.1
