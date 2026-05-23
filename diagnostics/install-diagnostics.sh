#!/usr/bin/env bash
#
# xKOR_3RR0R - Install Diagnostic System
# Sets up logging, crash reporting, and auto-commit
#

set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-/opt/xkor_3rr0r}"
DIAG_DIR="$PROJECT_ROOT/diagnostics"

echo "================================================================"
echo "  xKOR_3RR0R Diagnostic System Installer"
echo "================================================================"
echo ""

# Create directory structure
echo "[1/5] Creating diagnostic directories..."
mkdir -p "$DIAG_DIR"/{logs/{runtime,install,upgrade,frontend,backend,compositor,terminal,system},crashes,errors}
echo "   ✓ Directory structure created"

# Make scripts executable
echo "[2/5] Setting permissions..."
chmod +x "$DIAG_DIR"/crash-logger.sh 2>/dev/null || true
chmod +x "$PROJECT_ROOT"/os/bin/start-hyprland 2>/dev/null || true
echo "   ✓ Scripts made executable"

# Configure git to track diagnostics
echo "[3/5] Configuring git..."
cd "$PROJECT_ROOT"

# Remove diagnostics from .gitignore if present
if grep -q "^diagnostics/" .gitignore 2>/dev/null; then
    sed -i '/^diagnostics\//d' .gitignore
    echo "   ✓ Removed diagnostics/ from .gitignore"
fi

# Add crash/error directories to git but ignore logs (too large)
cat >> .gitignore <<'EOF'

# Diagnostic logs (too large for git, keep locally)
diagnostics/logs/
EOF

echo "   ✓ Git configured to track crash reports"

# Create README
echo "[4/5] Creating documentation..."
cat > "$DIAG_DIR/README.md" <<'EOF'
# xKOR_3RR0R Diagnostics

This directory contains automatic crash reporting and logging infrastructure.

## Directory Structure

```
diagnostics/
├── logs/              # Runtime logs (gitignored, too large)
│   ├── compositor/    # Hyprland/X11 logs
│   ├── runtime/       # Application runtime logs
│   ├── install/       # Installation logs
│   ├── upgrade/       # Upgrade logs
│   ├── frontend/      # Browser/Tauri logs
│   ├── backend/       # Rust backend logs
│   ├── terminal/      # PTY/terminal logs
│   └── system/        # System service logs
├── crashes/           # Full crash reports (tracked in git)
└── errors/            # Error logs (tracked in git)
```

## Crash Logger

Automatically captures system state when crashes occur:

```bash
./crash-logger.sh crash "compositor" "Hyprland socket init failed"
```

Features:
- Full system state dump
- Journalctl extraction
- Process listing
- Environment capture
- Automatic git commit

## Logs Location

All logs are timestamped: `YYYY-MM-DD_HH-MM-SS.log`

View recent crashes:
```bash
ls -lt diagnostics/crashes/
```

View live compositor logs:
```bash
tail -f diagnostics/logs/compositor/*.log
```

## Automatic Cleanup

Logs older than 7 days are automatically removed:
```bash
./crash-logger.sh cleanup
```

## Manual Investigation

After a crash:
1. Check `diagnostics/crashes/` for latest report
2. Review systemd journal: `journalctl -u xkor-login -e`
3. Check compositor logs: `diagnostics/logs/compositor/`
4. Git commit will be created automatically with crash details
EOF

echo "   ✓ README created"

# Update systemd service
echo "[5/5] Updating systemd service..."
if [[ -f "$PROJECT_ROOT/os/systemd/xkor-login.service" ]]; then
    sudo cp "$PROJECT_ROOT/os/systemd/xkor-login.service" /etc/systemd/system/
    sudo systemctl daemon-reload
    echo "   ✓ Systemd service updated with PAM support"
else
    echo "   ⚠ systemd service file not found, skipping"
fi

echo ""
echo "================================================================"
echo "  Installation Complete!"
echo "================================================================"
echo ""
echo "Diagnostic system installed at: $DIAG_DIR"
echo ""
echo "Next steps:"
echo "  1. Reboot to apply systemd changes: sudo reboot"
echo "  2. If crash occurs, check: diagnostics/crashes/"
echo "  3. Pull crash reports from git before working: git pull"
echo ""
echo "View logs:"
echo "  - Compositor: tail -f diagnostics/logs/compositor/*.log"
echo "  - Journal:    journalctl -u xkor-login -f"
echo ""
