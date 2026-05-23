# xKOR_3RR0R v2.1.0 - Deployment Guide

## 🔥 Critical Fix Deployed

**Version:** 2.1.0-beta.1  
**Release Date:** 2026-05-24  
**Status:** Hyprland PAM crash fix + comprehensive diagnostics

---

## 🎯 What Was Fixed

### Root Cause (Finally Identified!)

```
xkor-login.service (User=xkor, NO PAM)
  ↓
systemd-logind IGNORES the session
  ↓
/run/user/1000 NEVER CREATED
  ↓
start-hyprland manually exports XDG_RUNTIME_DIR=/run/user/1000
  ↓
Hyprland tries to mkdir /run/user/1000/hypr/
  ↓
💥 CRASH: Permission denied / Couldn't uniqfd
```

### The Real Fix

Added `PAMName=login` to xkor-login.service:
- systemd-logind NOW creates /run/user/UID
- Proper permissions (700, owned by xkor)
- Hyprland socket initialization succeeds
- Compositor starts cleanly

---

## 📦 What's New

### 1. Automatic Crash Logger
- **Location:** `diagnostics/crash-logger.sh`
- **Captures:**
  - Full system state
  - Kernel/memory/processes
  - User sessions and permissions
  - Compositor status
  - systemd journal (last 50 lines)
  - Environment variables
  - Bash stack traces
- **Auto-commits to git** with structured messages

### 2. Enhanced Compositor Startup
- **Location:** `os/bin/start-hyprland`
- **Features:**
  - Pre-flight validation
  - Automatic stale socket cleanup
  - Runtime directory verification
  - Comprehensive logging
  - Graceful error handling
- **Logs to:** `diagnostics/logs/compositor/`

### 3. Centralized Logging
```
diagnostics/
├── logs/              # gitignored (too large)
│   ├── compositor/    # Hyprland logs
│   ├── runtime/       # App runtime logs
│   ├── install/       # Installation logs
│   ├── upgrade/       # Upgrade logs
│   └── ...
├── crashes/           # tracked in git
└── errors/            # tracked in git
```

### 4. systemd Service Hardening
- `PAMName=login` - enables proper session
- `SyslogIdentifier=xkor-os` - easy filtering
- `Restart=on-failure` - auto-recovery
- Journal logging for all output

---

## 🚀 Deployment Steps

### On Your System (Arch Linux)

```bash
# 1. Navigate to project
cd /opt/xkor_3rr0r

# 2. Pull latest changes (includes crash reports if any were auto-committed)
git pull

# 3. Run upgrade script
./upgrade.sh
```

You'll see:
```
╔════════════════════════════════════════════╗
║  UPDATE AVAILABLE                          ║
╠════════════════════════════════════════════╣
║  Version: 2.0.2-beta.1 → 2.1.0-beta.1      ║
║  Commits: X new                            ║
╚════════════════════════════════════════════╝
```

```bash
# 4. Install diagnostic system
./diagnostics/install-diagnostics.sh
```

This will:
- Create log directories
- Set script permissions
- Update systemd service
- Reload systemd daemon

```bash
# 5. Reboot to apply systemd changes
sudo reboot
```

---

## ✅ Verification

After reboot, the system should:

1. **Boot to TTY1**
2. **Hyprland starts** (no crash)
3. **Tauri app loads**

### Check Logs

```bash
# Real-time compositor log
tail -f /opt/xkor_3rr0r/diagnostics/logs/compositor/*.log

# systemd journal
journalctl -u xkor-login -f

# Check for crashes
ls -lt /opt/xkor_3rr0r/diagnostics/crashes/
```

### If Still Crashes

The crash will be automatically captured and committed to git:

1. **Check local crash report:**
   ```bash
   cat /opt/xkor_3rr0r/diagnostics/crashes/*.log | less
   ```

2. **Push crash report to GitHub:**
   ```bash
   cd /opt/xkor_3rr0r
   git push
   ```

3. **On development machine:**
   ```bash
   cd C:\Users\matej\Downloads\xKOR_3RR0R
   git pull
   cat diagnostics/crashes/*.log
   ```

---

## 🔍 Debugging Tools

### Manual Crash Capture

```bash
./diagnostics/crash-logger.sh crash "compositor" "Manual test"
```

### Check PAM Session

```bash
# Verify runtime directory exists
ls -la /run/user/1000/

# Check session state
loginctl list-sessions
loginctl show-session <session-id>

# Check user runtime
systemctl --user status
```

### Test Hyprland Manually

```bash
# As xkor user
export XDG_RUNTIME_DIR=/run/user/1000
export XDG_SESSION_TYPE=wayland
Hyprland
```

If this works but systemd service fails, issue is in service config.

### Check Socket Cleanup

```bash
# Before starting
ls -la /run/user/1000/hypr/

# Should be empty or not exist
# start-hyprland will clean stale sockets automatically
```

---

## 📊 Expected Behavior

### Before Fix (v2.0.2)
```
[ERROR] Couldn't uniqfd for .sock2
[DEBUG] hyprland exit, breaking the poll
System stuck at black screen
```

### After Fix (v2.1.0)
```
[2026-05-24 01:23:45] Setting up Wayland environment...
[2026-05-24 01:23:45] Runtime directory OK: /run/user/1000
[2026-05-24 01:23:45] Cleaning up stale Hyprland sockets...
[2026-05-24 01:23:45] Pre-flight checks passed
[2026-05-24 01:23:45] Launching Hyprland compositor...
Hyprland v0.45.2 starting...
[success] Compositor initialized
[success] Tauri app launched
```

---

## 🆘 Recovery

If system is unbootable:

### Switch to TTY2
```
Ctrl + Alt + F2
```

Login as xkor, then:

```bash
# Disable xkor-login service
sudo systemctl disable xkor-login.service
sudo systemctl stop xkor-login.service

# Re-enable getty (standard login)
sudo systemctl enable getty@tty1.service
sudo systemctl start getty@tty1.service

# Reboot
sudo reboot
```

### Restore X11 Mode

If Hyprland continues to fail, revert to X11:

```bash
# Edit systemd service
sudo nano /etc/systemd/system/xkor-login.service

# Change ExecStart to:
ExecStart=/opt/xkor_3rr0r/os/xorg/xkor-session.sh

# Reload and reboot
sudo systemctl daemon-reload
sudo reboot
```

---

## 📝 Changelog

### v2.1.0-beta.1 (2026-05-24)

**CRITICAL FIX:**
- ✅ Added PAMName=login to xkor-login.service
- ✅ systemd-logind now creates /run/user/UID properly
- ✅ Hyprland socket initialization succeeds
- ✅ No more "Couldn't uniqfd" crashes

**NEW FEATURES:**
- ✨ Automatic crash logger with git auto-commit
- ✨ Centralized diagnostic logging system
- ✨ Enhanced start-hyprland with pre-flight checks
- ✨ Stale socket cleanup
- ✨ Comprehensive system state capture
- ✨ 7-day automatic log rotation

**IMPROVEMENTS:**
- 📊 All logs timestamped and structured
- 📊 systemd journal integration
- 📊 Crash reports tracked in git
- 📊 Bulk logs gitignored (keep local)

**FIXES:**
- 🐛 Fixed runtime directory creation
- 🐛 Fixed permission issues
- 🐛 Fixed socket initialization
- 🐛 Fixed PAM session registration

---

## 📚 Additional Resources

- **Crash Reports:** `diagnostics/crashes/`
- **Live Logs:** `diagnostics/logs/compositor/`
- **System Journal:** `journalctl -u xkor-login`
- **Git History:** `git log --oneline diagnostics/`

---

## ⚠️ Important Notes

1. **Always git pull before debugging** - crash reports may be auto-committed
2. **Check diagnostics/crashes/ first** after any crash
3. **Logs are local-only** - crashes are tracked in git
4. **PAM session is critical** - do NOT remove PAMName=login
5. **Runtime directory must exist** - systemd-logind creates it via PAM

---

## 🎉 Success Metrics

After deployment, you should have:
- ✅ Clean Hyprland startup
- ✅ No socket initialization errors
- ✅ Automatic crash capture if anything fails
- ✅ Git history of all crashes
- ✅ Comprehensive logs for debugging
- ✅ Zero manual intervention needed

---

**Version:** `2.1.0-beta.1`  
**Tag:** `v2.1.0-beta.1`  
**Deployed:** 2026-05-24
