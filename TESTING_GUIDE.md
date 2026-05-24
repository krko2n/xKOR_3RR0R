# xKOR_3RR0R - Testing & Verification Guide

This guide shows you how to verify the diagnostic system is working correctly.

---

## [OK][OK][OK][OK] STEP 1: Verify Rust Compilation

### On Windows (Current Environment)

You need Rust installed. Check if you have it:

```bash
rustc --version
cargo --version
```

If not installed, install Rust:
- Download from: https://rustup.rs/
- Or run: `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`

Then verify compilation:

```bash
cd src-tauri
cargo check
```

**Expected output:**
```
Checking xkor-3rr0r v2.1.0-beta.1
Finished dev [unoptimized + debuginfo] target(s) in X.XXs
```

**If errors occur:**
- Check the error message
- Most likely: missing `chrono` dependency (already added to Cargo.toml)
- Run: `cargo fetch` to download dependencies
- Run: `cargo build` to see detailed compilation errors

---

## [OK][OK][OK][OK] STEP 2: Test on Linux (Production Environment)

### Option A: If You Have a Linux VM/Machine

Transfer the project to Linux:

```bash
# On Windows, zip the project
cd C:/Users/matej/Downloads
tar -czf xKOR_3RR0R.tar.gz xKOR_3RR0R/

# Transfer to Linux (via SCP, USB, etc)
scp xKOR_3RR0R.tar.gz user@linux-machine:/tmp/

# On Linux, extract and install
cd /tmp
tar -xzf xKOR_3RR0R.tar.gz
cd xKOR_3RR0R
sudo bash install.sh --mode=os
```

### Option B: Install WSL2 (Windows Subsystem for Linux)

**Install WSL2 on Windows:**

```powershell
# In PowerShell (Admin)
wsl --install
# Restart computer

# After restart, install Arch Linux or Ubuntu
wsl --install -d Ubuntu
```

**Copy project to WSL:**

```bash
# In WSL terminal
cd ~
cp -r /mnt/c/Users/matej/Downloads/xKOR_3RR0R ./
cd xKOR_3RR0R
```

**Install in OS Mode:**

```bash
sudo bash install.sh --mode=os
```

### Option C: Test in App Mode (No OS Installation)

You can test most features without OS mode:

```bash
# On Linux or WSL
cd xKOR_3RR0R
npm install
npm run dev
```

This launches the app in development mode (not fullscreen OS replacement).

---

## [OK][OK][OK][OK] STEP 3: Trigger Intentional Crashes

### Test #1: Frontend JavaScript Error

**Create a test file:**

```bash
cd xKOR_3RR0R
cat > test-frontend-crash.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
  <title>Frontend Crash Test</title>
  <script src="src/js/error-logger.js"></script>
</head>
<body>
  <h1>xKOR Frontend Crash Test</h1>
  <button onclick="testUncaughtException()">Test Uncaught Exception</button>
  <button onclick="testUnhandledRejection()">Test Unhandled Rejection</button>
  <button onclick="testManualCrash()">Test Manual Crash</button>
  <button onclick="testFatal()">Test Fatal Error</button>

  <script>
    // Mock Tauri for testing
    window.__TAURI__ = {
      core: {
        invoke: async (cmd, args) => {
          console.log('MOCK TAURI INVOKE:', cmd, args);
          return { ok: true };
        }
      }
    };

    function testUncaughtException() {
      throw new Error('This is a test uncaught exception!');
    }

    function testUnhandledRejection() {
      Promise.reject('This is a test unhandled rejection!');
    }

    function testManualCrash() {
      window.reportCrash('manual_test', 'User clicked test button', { testData: 123 });
      alert('Crash reported! Check console and diagnostics/logs/');
    }

    function testFatal() {
      window.reportFatal('Test fatal error', new Error('Intentional test crash'));
    }
  </script>
</body>
</html>
EOF
```

**Open in browser:**

```bash
# Open test file
firefox test-frontend-crash.html
# or
chrome test-frontend-crash.html
```

Click the test buttons and check:
- Browser console for error messages
- Check if logs appear in `diagnostics/logs/frontend/`

### Test #2: Backend Rust Panic

**Create a test command:**

Edit `src-tauri/src/commands/system.rs` and add:

```rust
#[tauri::command]
pub async fn test_panic() {
    panic!("This is a test panic for diagnostic verification!");
}
```

Register it in `src-tauri/src/lib.rs`:

```rust
.invoke_handler(tauri::generate_handler![
    // ... existing commands ...
    commands::system::test_panic,  // Add this
])
```

Call from frontend:

```javascript
// In browser console while app is running
await window.__TAURI__.core.invoke('test_panic');
```

**Expected result:**
- App crashes
- Panic logged to `diagnostics/logs/backend/`
- Crash report in `diagnostics/crashes/`
- Git commit created (if in git repo)

### Test #3: Bash Crash Logger

**Manual test:**

```bash
cd xKOR_3RR0R

# Test crash logging
PROJECT_ROOT="$(pwd)" bash diagnostics/crash-logger.sh crash "test_crash" "Testing diagnostic system"

# Check output
ls -lt diagnostics/crashes/
cat diagnostics/crashes/*.log | head -50
```

**Expected result:**
- New file in `diagnostics/crashes/TIMESTAMP_crash.log`
- File contains system information
- Git commit created (if in repo)

### Test #4: Git Auto-Commit

**Verify git integration:**

```bash
cd xKOR_3RR0R

# Trigger a crash
PROJECT_ROOT="$(pwd)" bash diagnostics/crash-logger.sh crash "git_test" "Testing auto-commit"

# Check if file was staged
git status

# Check if commit was created
git log --oneline -1 | grep "crash:"
```

**Expected output:**
```
crash: 2026-05-24_XX-XX-XX - git_test
```

---

## [OK][OK][OK][OK] STEP 4: Monitor Logs

### Real-Time Log Monitoring

**Watch frontend logs:**

```bash
# Terminal 1 - Watch frontend logs
watch -n 1 'ls -lth diagnostics/logs/frontend/ | head -10'

# Terminal 2 - Tail latest log
tail -f diagnostics/logs/frontend/*.log
```

**Watch backend logs:**

```bash
tail -f diagnostics/logs/backend/*.log
```

**Watch compositor logs (OS mode only):**

```bash
tail -f diagnostics/logs/compositor/*.log
```

**Watch systemd journal (OS mode only):**

```bash
journalctl -u xkor-login -f
```

### Check Log Contents

**List all logs:**

```bash
find diagnostics/logs -type f -name "*.log"
```

**View recent frontend errors:**

```bash
cat diagnostics/logs/frontend/*.log | tail -50
```

**View crash reports:**

```bash
ls -lth diagnostics/crashes/
cat diagnostics/crashes/*.log | less
```

---

## [OK][OK][OK][OK] STEP 5: Review Git Commit History

### View Crash Commits

**List all crash-related commits:**

```bash
git log --grep="^crash:" --oneline
```

**Example output:**
```
a1b2c3d crash: 2026-05-24_13-04-44 - test_crash
e4f5g6h crash: 2026-05-24_12-30-15 - hyprland_crash
```

**View full commit message:**

```bash
git log --grep="^crash:" --format=full -1
```

**View crash report from commit:**

```bash
# Get latest crash commit
git log --grep="^crash:" --oneline -1

# Show the crash log file
git show HEAD:diagnostics/crashes/TIMESTAMP_crash.log
```

### View Changes in Last Commit

```bash
git show HEAD
```

### Pull Crash Reports from Remote

If you're working in a team and crashes happen on another machine:

```bash
# Pull latest commits (includes crash reports)
git pull origin main

# List new crash reports
ls -lth diagnostics/crashes/ | head -10
```

---

## [OK][OK][OK] VERIFICATION CHECKLIST

Use this checklist to verify everything works:

### Frontend Tests

- [ ] Error logger loads: Open browser console, check for `[xKOR] Error logger initialized`
- [ ] `window.reportCrash` exists: Type `typeof window.reportCrash` [OK][OK][OK] should be `"function"`
- [ ] `window.reportFatal` exists: Type `typeof window.reportFatal` [OK][OK][OK] should be `"function"`
- [ ] Uncaught exception captured: Throw error, check console and logs
- [ ] Unhandled rejection captured: Reject promise, check console and logs
- [ ] Logs created: Check `diagnostics/logs/frontend/` for `.log` files

### Backend Tests

- [ ] Rust compiles: `cargo check` passes
- [ ] Panic hook installed: Intentional panic creates log file
- [ ] Backend logs created: Check `diagnostics/logs/backend/`
- [ ] Crash logger called: Panic triggers `crash-logger.sh`

### Integration Tests

- [ ] Frontend [OK][OK][OK] Backend: Error logged via Tauri IPC
- [ ] Backend [OK][OK][OK] Crash Logger: Rust panic triggers bash script
- [ ] Crash Logger [OK][OK][OK] Git: Crash report auto-committed
- [ ] End-to-end: Frontend crash [OK][OK][OK] Backend log [OK][OK][OK] Crash report [OK][OK][OK] Git commit

### Git Tests

- [ ] Crash file created: `ls diagnostics/crashes/`
- [ ] File not ignored: `git check-ignore diagnostics/crashes/*.log` returns nothing
- [ ] File can be added: `git add diagnostics/crashes/*.log` works
- [ ] Commit created: `git log --grep="^crash:"` shows commits
- [ ] Commit message correct: Contains crash type, timestamp, log path

---

## [OK][OK][OK][OK] TROUBLESHOOTING

### Problem: "cargo: command not found"

**Solution:**
```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Reload shell
source $HOME/.cargo/env

# Verify
cargo --version
```

### Problem: "chrono not found" compilation error

**Solution:**
```bash
cd src-tauri
cargo fetch    # Download dependencies
cargo build    # Rebuild
```

### Problem: No logs created in diagnostics/logs/

**Check permissions:**
```bash
ls -la diagnostics/logs/
chmod -R u+w diagnostics/logs/
```

**Check if directories exist:**
```bash
ls -la diagnostics/logs/frontend/
ls -la diagnostics/logs/backend/
```

### Problem: Git commit not created

**Check if in git repo:**
```bash
git status
# If error: run `git init`
```

**Check if crash-logger is executable:**
```bash
chmod +x diagnostics/crash-logger.sh
```

**Manual test:**
```bash
PROJECT_ROOT="$(pwd)" bash diagnostics/crash-logger.sh crash "test" "manual test"
git status  # Should show new file
git log -1  # Should show commit
```

### Problem: Frontend errors not reaching backend

**Check Tauri IPC:**
```bash
# In browser console
window.__TAURI__.core.invoke('log_frontend_error', {
  channel: 'test',
  timestamp: new Date().toISOString(),
  type: 'test',
  message: 'Manual test from console'
});
```

**Check backend registered command:**
```bash
# In src-tauri/src/lib.rs, verify:
grep "log_frontend_error" src-tauri/src/lib.rs
```

### Problem: Crash logger fails on Windows

**Expected behavior:**
- Some Linux commands (uptime, free) will fail
- Script continues and logs "(command failed)"
- Core functionality still works (log creation, git commit)

**Workaround:**
- Test on Linux/WSL for full functionality
- Or install Linux utilities for Git Bash (busybox, cygwin)

---

## [OK][OK][OK][OK] SUCCESS CRITERIA

You'll know the system is working when:

1. [OK][OK][OK] **Rust compiles**: `cargo check` passes with no errors
2. [OK][OK][OK] **Logs are created**: `find diagnostics/logs -type f` shows files
3. [OK][OK][OK] **Crashes are captured**: `ls diagnostics/crashes/` shows timestamped logs
4. [OK][OK][OK] **Git commits exist**: `git log --grep="^crash:"` shows auto-commits
5. [OK][OK][OK] **Frontend errors logged**: Browser errors appear in `diagnostics/logs/frontend/`
6. [OK][OK][OK] **Backend panics logged**: Rust panics appear in `diagnostics/logs/backend/`
7. [OK][OK][OK] **End-to-end works**: Crash [OK][OK][OK] Log [OK][OK][OK] Report [OK][OK][OK] Git commit (all automatic)

---

## [OK][OK][OK][OK] QUICK REFERENCE

### Essential Commands

```bash
# Verify compilation
cd src-tauri && cargo check

# Run app in dev mode
npm run dev

# Trigger test crash
PROJECT_ROOT="$(pwd)" bash diagnostics/crash-logger.sh crash "test" "Testing"

# Monitor logs
tail -f diagnostics/logs/*/*.log

# View crash reports
ls -lth diagnostics/crashes/

# Check git commits
git log --grep="^crash:" --oneline

# Cleanup old logs
bash diagnostics/crash-logger.sh cleanup
```

---

## [OK][OK][OK][OK] ADDITIONAL RESOURCES

- **Full Documentation**: `diagnostics/LOGGING.md`
- **Analysis Report**: `DIAGNOSTIC_ANALYSIS_REPORT.md`
- **Project README**: `README.md` (if exists)
- **Crash Logger Help**: `bash diagnostics/crash-logger.sh help`

---

**Good luck testing! [OK][OK][OK][OK]**

If you encounter issues, check the troubleshooting section above or review `DIAGNOSTIC_ANALYSIS_REPORT.md` for detailed technical analysis.
