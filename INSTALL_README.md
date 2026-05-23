# xKOR_3RR0R - Installation Guide

Professional installation system for xKOR_3RR0R v2.0.0+

## Quick Start

### Installation (One Command)

```bash
git clone https://github.com/krko2n/xKOR_3RR0R
cd xKOR_3RR0R
./install.sh
```

**That's it!** The installer will:
- Detect your Linux distribution
- Install all dependencies automatically
- Build the Rust backend
- Set up configs and launchers
- Create desktop entries

### Running

```bash
xkor
```

Or from menu: Applications → System → xKOR_3RR0R

---

## Installation Modes

### App Mode (Default)

Runs xKOR_3RR0R as a window application.

```bash
./install.sh
```

**Best for:** Most users, testing, development

### OS Mode (Advanced)

Replaces your desktop environment (Arch Linux only).

```bash
sudo ./install.sh --mode=os
```

**Best for:** Dedicated xKOR machines, cyberpunk workstations

---

## System Requirements

### Minimum

- **OS**: Linux (Debian, Ubuntu, Arch, Fedora, openSUSE)
- **CPU**: x86_64 (64-bit)
- **RAM**: 2GB
- **Disk**: 500MB free space
- **Node.js**: 18+
- **Rust**: 1.70+

### Recommended

- **RAM**: 4GB+
- **GPU**: WebGL-capable for 3D globe
- **Display**: 1920x1080 or higher

---

## Supported Distributions

| Distribution | Status | Package Manager |
|--------------|--------|-----------------|
| **Arch Linux** | ✅ Full support | pacman |
| **Ubuntu/Debian** | ✅ Full support | apt |
| **Fedora** | ✅ Full support | dnf |
| **openSUSE** | ✅ Full support | zypper |
| **Manjaro** | ✅ Full support | pacman |
| **Alpine** | ⚠️ Experimental | apk |
| **Other** | ⚠️ May work | Manual deps |

---

## Installation Options

### Basic Options

```bash
./install.sh [OPTIONS]
```

| Option | Description |
|--------|-------------|
| `--mode=app` | App Mode (default) |
| `--mode=os` | OS Mode (requires sudo) |
| `--os` | Shortcut for `--mode=os` |
| `--app` | Shortcut for `--mode=app` |

### Advanced Options

| Option | Description |
|--------|-------------|
| `--dev` | Development mode (debug build) |
| `--no-audio` | Disable audio system |
| `--portable` | Portable mode (configs in project dir) |
| `--skip-build` | Skip cargo build (use existing binary) |
| `-v, --verbose` | Verbose output |
| `-h, --help` | Show help |

### Examples

```bash
# Standard installation
./install.sh

# OS Mode (replaces desktop)
sudo ./install.sh --mode=os

# Development install
./install.sh --dev --verbose

# Portable install (no system integration)
./install.sh --portable
```

---

## Upgrade

### One-Command Upgrade

```bash
./upgrade.sh
```

The upgrader will:
- Create automatic backup
- Pull latest changes
- Update dependencies
- Rebuild project
- Preserve user settings
- Rollback on failure

### Upgrade Options

```bash
./upgrade.sh [OPTIONS]
```

| Option | Description |
|--------|-------------|
| `--force` | Skip confirmation prompts |
| `--no-backup` | Skip creating backup |
| `--dev` | Development mode |
| `-v, --verbose` | Verbose output |

### Examples

```bash
# Standard upgrade
./upgrade.sh

# Force upgrade (no prompts)
./upgrade.sh --force

# Upgrade without backup (not recommended)
./upgrade.sh --no-backup
```

---

## Uninstall

### Complete Removal

```bash
./uninstall.sh
```

### Uninstall Options

| Option | Description |
|--------|-------------|
| `--purge` | Remove all data including configs |
| `--keep-config` | Keep configuration files |
| `--force` | Skip confirmation |

### Examples

```bash
# Remove but keep configs
./uninstall.sh --keep-config

# Complete removal
./uninstall.sh --purge

# Quick uninstall
./uninstall.sh --force
```

---

## Diagnostics

### Check System Health

```bash
./xkor-doctor.sh
```

The doctor will check:
- System information
- Required dependencies
- Rust toolchain
- Node.js environment
- Tauri dependencies
- Project status
- Installation status

### Diagnostic Options

```bash
./xkor-doctor.sh [OPTIONS]
```

| Option | Description |
|--------|-------------|
| `--fix` | Attempt to fix detected issues |
| `-v, --verbose` | Show verbose output |

### Examples

```bash
# Check system
./xkor-doctor.sh

# Check and fix issues
./xkor-doctor.sh --fix

# Verbose diagnostics
./xkor-doctor.sh --verbose
```

---

## Troubleshooting

### Installation Failed

1. **Check system requirements:**
   ```bash
   ./xkor-doctor.sh
   ```

2. **Install missing dependencies:**
   ```bash
   ./xkor-doctor.sh --fix
   ```

3. **Check installation log:**
   ```bash
   cat ~/.local/state/xkor_3rr0r/logs/install_*.log
   ```

### Binary Not Found

```bash
# Rebuild project
cd src-tauri
cargo build --release
```

### Dependencies Missing

**Debian/Ubuntu:**
```bash
sudo apt install libwebkit2gtk-4.1-dev libgtk-3-dev build-essential
```

**Arch:**
```bash
sudo pacman -S webkit2gtk-4.1 gtk3 base-devel
```

**Fedora:**
```bash
sudo dnf install webkit2gtk4.1-devel gtk3-devel gcc
```

### Rust Not Found

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
```

### Node.js Too Old

Install Node.js 18+ from [nodejs.org](https://nodejs.org/)

Or use nvm:
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install 18
nvm use 18
```

---

## Manual Installation

If automatic installer fails, follow these steps:

### 1. Install Dependencies

**Debian/Ubuntu:**
```bash
sudo apt update
sudo apt install -y git curl wget build-essential pkg-config libssl-dev \
    libwebkit2gtk-4.1-dev libgtk-3-dev libayatana-appindicator3-dev \
    librsvg2-dev libsoup-3.0-dev nodejs npm
```

**Arch:**
```bash
sudo pacman -Syu --needed git curl wget base-devel \
    webkit2gtk-4.1 gtk3 libappindicator-gtk3 librsvg libsoup3 \
    nodejs npm
```

**Fedora:**
```bash
sudo dnf install -y git curl wget gcc gcc-c++ make openssl-devel \
    webkit2gtk4.1-devel gtk3-devel libappindicator-gtk3-devel \
    librsvg2-devel libsoup3-devel nodejs npm
```

### 2. Install Rust

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
```

### 3. Clone Repository

```bash
git clone https://github.com/krko2n/xKOR_3RR0R
cd xKOR_3RR0R
```

### 4. Install Frontend Dependencies

```bash
npm install
```

### 5. Build Rust Backend

```bash
cd src-tauri
cargo build --release
cd ..
```

### 6. Create Launcher

```bash
sudo tee /usr/local/bin/xkor > /dev/null <<'EOF'
#!/bin/bash
cd "$HOME/xKOR_3RR0R"
exec ./src-tauri/target/release/xkor-3rr0r "$@"
EOF

sudo chmod +x /usr/local/bin/xkor
```

### 7. Run

```bash
xkor
```

---

## Development

### Development Mode

```bash
./install.sh --dev
```

Or manually:

```bash
npm run dev
```

### Hot Reload

```bash
npm run dev
```

Frontend changes reload automatically.
Rust changes require restart.

### Debug Build

```bash
cd src-tauri
cargo build
cd ..
npm run dev
```

---

## Directory Structure

### User Directories

```
~/.config/xkor_3rr0r/        # Configuration
~/.local/share/xkor_3rr0r/   # Data and themes
~/.cache/xkor_3rr0r/         # Cache
~/.local/state/xkor_3rr0r/   # Logs
```

### System Directories (OS Mode)

```
/opt/xkor_3rr0r/                      # Installation
/usr/local/bin/xkor                   # Launcher
/etc/systemd/system/xkor-login.service # Service
~/.local/share/applications/xkor_3rr0r.desktop # Desktop entry
```

---

## FAQ

### Q: Which mode should I use?

**A:** Use **App Mode** unless you want xKOR_3RR0R to completely replace your desktop environment.

### Q: Can I switch between modes?

**A:** Yes, but you need to uninstall first:
```bash
./uninstall.sh
./install.sh --mode=<new-mode>
```

### Q: How do I update?

**A:** Simply run `./upgrade.sh`

### Q: Where are my configs?

**A:** `~/.config/xkor_3rr0r/`

### Q: Can I customize themes?

**A:** Yes, themes are in `~/.local/share/xkor_3rr0r/themes/`

### Q: Installation takes forever?

**A:** First Rust build can take 5-10 minutes. Grab a coffee ☕

### Q: How do I uninstall?

**A:** `./uninstall.sh --purge`

### Q: Can I run from USB?

**A:** Yes, use portable mode: `./install.sh --portable`

### Q: Does it work on non-Arch for OS Mode?

**A:** OS Mode is Arch-only. Use App Mode on other distros.

### Q: Can I contribute?

**A:** Yes! Fork the repo and submit PRs.

---

## Support

- **GitHub Issues**: https://github.com/krko2n/xKOR_3RR0R/issues
- **Documentation**: See `CLAUDE.md` and `MIGRATION_GUIDE.md`
- **Agent Instructions**: See `AGENT.md`

---

## License

MIT License - See LICENSE file

---

## Credits

Created by [krko2n](https://github.com/krko2n)

Inspired by [eDEX-UI](https://github.com/GitSquared/edex-ui)

Built with:
- [Tauri v2](https://tauri.app/)
- [Rust](https://www.rust-lang.org/)
- [Three.js](https://threejs.org/)
- [xterm.js](https://xtermjs.org/)
