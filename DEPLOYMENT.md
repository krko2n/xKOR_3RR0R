# xKOR_3RR0R v2.1.0 - Deployment Guide

## [OK][OK][OK][OK] Critical Fix Deployed

**Version:** 2.1.0-beta.1  
**Release Date:** 2026-05-24  
**Status:** Hyprland PAM crash fix + comprehensive diagnostics

---

## [OK][OK][OK][OK] What Was Fixed

### Root Cause (Finally Identified!)

```
xkor-login.service (User=xkor, NO PAM)
  [OK][OK][OK]
systemd-logind IGNORES the session
  [OK][OK][OK]
/run/user/1000 NEVER CREATED
  [OK][OK][OK]
start-hyprland manually exports XDG_RUNTIME_DIR=/run/user/1000
  [OK][OK][OK]
Hyprland tries to mkdir /run/user/1000/hypr/
  [OK][OK][OK]
[OK][OK][OK][OK] CRASH: Permission denied / Couldn't uniqfd
```

### The Real Fix

Added `PAMName=login` to xkor-login.service:
- systemd-logind NOW creates /run/user/UID
- Proper permissions (700, owned by xkor)
- Hyprland socket initialization succeeds
- Compositor starts cleanly

---

## [OK][OK][OK][OK] What's New

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
[OK][OK][OK][OK][OK][OK][OK][OK][OK] logs/              # gitignored (too large)
[OK][OK][OK]   [OK][OK][OK][OK][OK][OK][OK][OK][OK] compositor/    # Hyprland logs
[OK][OK][OK]   [OK][OK][OK][OK][OK][OK][OK][OK][OK] runtime/       # App runtime logs
[OK][OK][OK]   [OK][OK][OK][OK][OK][OK][OK][OK][OK] install/       # Installation logs
[OK][OK][OK]   [OK][OK][OK][OK][OK][OK][OK][OK][OK] upgrade/       # Upgrade logs
[OK][OK][OK]   [OK][OK][OK][OK][OK][OK][OK][OK][OK] ...
[OK][OK][OK][OK][OK][OK][OK][OK][OK] crashes/           # tracked in git
[OK][OK][OK][OK][OK][OK][OK][OK][OK] errors/            # tracked in git
```

### 4. systemd Service Hardening
- `PAMName=login` - enables proper session
- `SyslogIdentifier=xkor-os` - easy filtering
- `Restart=on-failure` - auto-recovery
- Journal logging for all output

---

## [OK][OK][OK][OK] Deployment Steps

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
[OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK]
[OK][OK][OK]  UPDATE AVAILABLE                          [OK][OK][OK]
[OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK]
[OK][OK][OK]  Version: 2.0.2-beta.1 [OK][OK][OK] 2.1.0-beta.1      [OK][OK][OK]
[OK][OK][OK]  Commits: X new                            [OK][OK][OK]
[OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK][OK]
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

## [OK][OK][OK] Verification

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

## [OK][OK][OK][OK] Debugging Tools

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

## [OK][OK][OK][OK] Expected Behavior

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

## [OK][OK][OK][OK] Recovery

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

## [OK][OK][OK][OK] Changelog

### v2.1.0-beta.1 (2026-05-24)

**CRITICAL FIX:**
- [OK][OK][OK] Added PAMName=login to xkor-login.service
- [OK][OK][OK] systemd-logind now creates /run/user/UID properly
- [OK][OK][OK] Hyprland socket initialization succeeds
- [OK][OK][OK] No more "Couldn't uniqfd" crashes

**NEW FEATURES:**
- [OK][OK][OK] Automatic crash logger with git auto-commit
- [OK][OK][OK] Centralized diagnostic logging system
- [OK][OK][OK] Enhanced start-hyprland with pre-flight checks
- [OK][OK][OK] Stale socket cleanup
- [OK][OK][OK] Comprehensive system state capture
- [OK][OK][OK] 7-day automatic log rotation

**IMPROVEMENTS:**
- [OK][OK][OK][OK] All logs timestamped and structured
- [OK][OK][OK][OK] systemd journal integration
- [OK][OK][OK][OK] Crash reports tracked in git
- [OK][OK][OK][OK] Bulk logs gitignored (keep local)

**FIXES:**
- [OK][OK][OK][OK] Fixed runtime directory creation
- [OK][OK][OK][OK] Fixed permission issues
- [OK][OK][OK][OK] Fixed socket initialization
- [OK][OK][OK][OK] Fixed PAM session registration

---

## [OK][OK][OK][OK] Additional Resources

- **Crash Reports:** `diagnostics/crashes/`
- **Live Logs:** `diagnostics/logs/compositor/`
- **System Journal:** `journalctl -u xkor-login`
- **Git History:** `git log --oneline diagnostics/`

---

## [OK][OK][OK][OK][OK][OK] Important Notes

1. **Always git pull before debugging** - crash reports may be auto-committed
2. **Check diagnostics/crashes/ first** after any crash
3. **Logs are local-only** - crashes are tracked in git
4. **PAM session is critical** - do NOT remove PAMName=login
5. **Runtime directory must exist** - systemd-logind creates it via PAM

---

## [OK][OK][OK][OK] Success Metrics

After deployment, you should have:
- [OK][OK][OK] Clean Hyprland startup
- [OK][OK][OK] No socket initialization errors
- [OK][OK][OK] Automatic crash capture if anything fails
- [OK][OK][OK] Git history of all crashes
- [OK][OK][OK] Comprehensive logs for debugging
- [OK][OK][OK] Zero manual intervention needed

---

**Version:** `2.1.0-beta.1`  
**Tag:** `v2.1.0-beta.1`  
**Deployed:** 2026-05-24
