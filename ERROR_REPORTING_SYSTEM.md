# xKOR_3RR0R - Automated Error Reporting & GitHub Integration

## [TARGET] Overview

This document describes the **fully automated** error reporting, logging, and GitHub issue management system for xKOR_3RR0R.

**ONE COMMAND to set everything up:**

```bash
./upgrade.sh
```

---

## [PACKAGE] What Gets Installed

When you run `./upgrade.sh`, the system automatically:

1. [OK] Updates the project to latest version
2. [OK] Installs all dependencies (Python, jq, gh CLI, sqlite)
3. [OK] Sets up error logging infrastructure
4. [OK] Creates crash report generators
5. [OK] Configures GitHub issue automation
6. [OK] Sets up background monitoring service
7. [OK] Implements issue deduplication
8. [OK] Configures rate limiting
9. [OK] Creates systemd services (if available)
10. [OK] Verifies everything works

---

## 🏗️ Architecture

### Components

```
xKOR_3RR0R/
├── upgrade.sh                          # Main upgrade script
├── scripts/
│   ├── error-reporting/
│   │   ├── collect-error-data.sh      # Collects logs, environment, stack traces
│   │   ├── generate-error-report.py   # Generates markdown reports
│   │   ├── github-issue-manager.py    # Creates/updates GitHub issues
│   │   ├── report-error.sh            # Main entry point
│   │   ├── dedup-manager.sh           # Manages deduplication database
│   │   └── init-dedup-db.sql          # Database schema
│   ├── create-error-reporting.sh      # Setup script
│   ├── create-github-integration.sh   # Setup script
│   ├── create-monitoring-service.sh   # Setup script
│   ├── create-deduplication.sh        # Setup script
│   └── test-error-reporting.sh        # Test suite
├── .github/
│   ├── monitoring/
│   │   ├── log-monitor.sh             # Background monitor daemon
│   │   ├── xkor-monitor.service       # Systemd service file
│   │   ├── start-monitor.sh           # Manual start script
│   │   └── stop-monitor.sh            # Stop script
│   └── issue_cache.db                 # Deduplication database
├── crash_reports/                     # Generated crash reports
└── diagnostics/                       # Existing diagnostic system
    ├── crashes/                       # Crash logs
    ├── errors/                        # Error logs
    └── logs/                          # Runtime logs
```

---

## [LAUNCH] Quick Start

### Installation

```bash
# Clone or update repository
cd xKOR_3RR0R

# Run automated upgrade (does everything)
./upgrade.sh

# Optional: Skip services if not using systemd
./upgrade.sh --skip-services

# Optional: Skip GitHub if you don't have credentials
./upgrade.sh --skip-github
```

### Verification

```bash
# Test the error reporting system
./scripts/test-error-reporting.sh

# Check if monitoring service is running
systemctl status xkor-monitor

# Or manually start monitoring
./.github/monitoring/start-monitor.sh
```

---

## [STATS] How It Works

### Automatic Error Detection

The system monitors:

- **Log files**: `diagnostics/logs/**/*.log`
- **Crash reports**: `diagnostics/crashes/*.log`
- **Systemd journal**: `journalctl -u xkor-login`
- **Frontend errors**: JavaScript exceptions
- **Backend panics**: Rust panics

### Monitored Patterns

- `ERROR`
- `FATAL`
- `PANIC`
- `EXCEPTION`
- `SEGFAULT`
- `SIGSEGV`
- `core dumped`

### Error Flow

```
┌─────────────┐
│   Crash     │
│  Detected   │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────┐
│ 1. Collect Error Data           │
│    • Logs (last 50 lines)       │
│    • Stack trace                │
│    • System info                │
│    • Environment variables      │
│    • Git commit hash            │
└──────┬──────────────────────────┘
       │
       ▼
┌─────────────────────────────────┐
│ 2. Sanitize Secrets             │
│    • Remove tokens              │
│    • Remove passwords           │
│    • Remove API keys            │
└──────┬──────────────────────────┘
       │
       ▼
┌─────────────────────────────────┐
│ 3. Generate Signature           │
│    • SHA256 hash of:            │
│      - Error type               │
│      - Stack trace              │
└──────┬──────────────────────────┘
       │
       ▼
┌─────────────────────────────────┐
│ 4. Check Deduplication DB       │
│    • Does issue exist?          │
│    • Is it recent?              │
│    • How many occurrences?      │
└──────┬──────────────────────────┘
       │
       ├──[EXISTS]──────────┐
       │                    │
       │                    ▼
       │         ┌─────────────────────┐
       │         │ Update Existing     │
       │         │ • Add comment       │
       │         │ • Increment count   │
       │         └─────────────────────┘
       │
       └──[NEW]─────────────┐
                            │
                            ▼
                 ┌─────────────────────┐
                 │ Create New Issue    │
                 │ • Post to GitHub    │
                 │ • Record in DB      │
                 └─────────────────────┘
```

---

## [KEY] Issue Deduplication

### How It Works

Each error generates a **unique signature**:

```python
signature = sha256(f"{error_type}:{stack_trace}").hexdigest()[:16]
```

The signature is stored in a local SQLite database:

```sql
CREATE TABLE issues (
    signature TEXT UNIQUE,
    github_issue_number INTEGER,
    occurrence_count INTEGER,
    first_seen TEXT,
    last_seen TEXT,
    status TEXT
);
```

### Deduplication Logic

1. **New error** → Create new GitHub issue
2. **Existing error** → Add comment to existing issue
3. **>10 occurrences** → Stop spamming, only update DB
4. **5-minute cooldown** → Rate limiting between reports

### Managing Deduplications

```bash
# View all tracked issues
./scripts/error-reporting/dedup-manager.sh list

# Show statistics
./scripts/error-reporting/dedup-manager.sh stats

# Query specific signature
./scripts/error-reporting/dedup-manager.sh query abc123def456
```

---

## [GITHUB] GitHub Integration

### Authentication

The system uses **GitHub CLI** for authentication:

```bash
# Install GitHub CLI
sudo apt install gh          # Ubuntu/Debian
sudo pacman -S github-cli    # Arch Linux
brew install gh              # macOS

# Authenticate
gh auth login
```

### Created Issue Labels

The upgrade script automatically creates these labels:

- [BUG] **bug** - Bug reports
- [AI] **auto-report** - Automated reports
- [CRASH] **crash** - Crash reports
- [AI] **ai-debug** - AI-readable format

### Issue Format

Generated issues include:

```markdown
## xKOR_3RR0R Crash Report

**Timestamp:** 2026-05-24 14:30:45
**Error Type:** `frontend_crash`
**Version:** `2.1.0-beta.1`
**Commit:** `a1b2c3d4`
**Branch:** `main`

### Error Message
...

### Stack Trace
...

### System Information
- OS: Ubuntu 22.04.3 LTS
- Kernel: 5.15.0-89-generic
- Architecture: x86_64

### Recent Logs
...

### Error Signature
`abc123def456`
```

---

## [MONITOR] Background Monitoring

### Systemd Service (Recommended)

```bash
# Enable and start
sudo systemctl enable xkor-monitor.service
sudo systemctl start xkor-monitor.service

# Check status
systemctl status xkor-monitor

# View logs
journalctl -u xkor-monitor -f
```

### Manual Monitoring (No systemd)

```bash
# Start in background
./.github/monitoring/start-monitor.sh

# Stop
./.github/monitoring/stop-monitor.sh

# Check if running
ps aux | grep log-monitor
```

### Monitoring Configuration

- **Check interval**: 60 seconds
- **Cooldown**: 5 minutes between duplicate reports
- **Resource limits**:
  - CPU: 10% max
  - Memory: 100MB max

---

## [TEST] Testing

### Run Test Suite

```bash
# Run all tests
./scripts/test-error-reporting.sh

# Run individual tests
./scripts/test-error-reporting.sh data       # Data collection
./scripts/test-error-reporting.sh report     # Report generation
./scripts/test-error-reporting.sh dedup      # Deduplication
./scripts/test-error-reporting.sh github     # GitHub CLI
./scripts/test-error-reporting.sh pipeline   # Full pipeline
```

### Simulate Crash

```bash
# Trigger test crash report
./scripts/error-reporting/report-error.sh \
    "test_crash" \
    "This is a test crash - please ignore" \
    "test_function() at test.rs:42"

# Check if issue was created
gh issue list --label auto-report
```

---

## [TOOLS] Manual Usage

### Report an Error Manually

```bash
./scripts/error-reporting/report-error.sh \
    "error_type" \
    "Error message" \
    "Stack trace (optional)"
```

### Generate Report Without GitHub

```bash
# 1. Collect data
./scripts/error-reporting/collect-error-data.sh \
    "crash_type" \
    "Crash message" \
    > /tmp/error.json

# 2. Generate report
python3 ./scripts/error-reporting/generate-error-report.py \
    /tmp/error.json \
    > /tmp/report.json

# 3. View report
jq -r .markdown /tmp/report.json
```

---

## [SECURITY] Security & Privacy

### What Gets Sanitized

The system automatically removes:

- API tokens
- Passwords
- Secret keys
- Authentication credentials
- Environment variables containing sensitive data

### What Does NOT Get Uploaded

- Full log files (only last 50 lines per file)
- Entire home directory
- Binary files
- Node modules
- Compiled artifacts

### Rate Limiting

- **5-minute cooldown** between reports of same error
- **Maximum 10 occurrences** before stopping GitHub posts
- Database continues tracking all occurrences

---

## [AI] AI Integration

### AI-Readable Format

Reports are optimized for Claude Code, Cursor, and other AI agents:

- **Structured markdown**: Clear sections, code blocks
- **Complete context**: Version, commit, environment
- **Stack traces**: Preserved with line numbers
- **Error signatures**: For grouping similar issues
- **System info**: Architecture, OS, kernel
- **Reproduction hints**: When detectable

### Using with Claude Code

Claude Code can automatically:

1. Read crash reports from issues
2. Analyze stack traces
3. Identify root causes
4. Suggest fixes
5. Generate patches

```bash
# In Claude Code
Read the latest crash report from GitHub issues
```

---

## [GRAPH] Statistics

### View Error Statistics

```bash
./scripts/error-reporting/dedup-manager.sh stats
```

Output:

```
=== Issue Statistics ===

Total unique errors: 23
Open issues: 15
Total occurrences: 147

Top 10 most frequent errors:
error_type           occurrence_count  github_issue_number
-------------------  ----------------  -------------------
frontend_crash       42                #123
hyprland_socket      28                #124
pty_exec_failed      19                #125
...
```

---

## [BUG] Troubleshooting

### Issue Not Created

**Check GitHub CLI authentication:**

```bash
gh auth status
# If not authenticated:
gh auth login
```

**Check if labels exist:**

```bash
gh label list
# If missing:
gh label create "auto-report" --color "0e8a16"
```

### Monitoring Not Working

**Check if service is running:**

```bash
systemctl status xkor-monitor

# If failed, check logs:
journalctl -u xkor-monitor -n 50
```

**Manual start:**

```bash
./.github/monitoring/start-monitor.sh
```

### Database Errors

**Reinitialize database:**

```bash
rm -f .github/issue_cache.db
./scripts/error-reporting/dedup-manager.sh init
```

### Too Many Issues Created

**Check deduplication:**

```bash
./scripts/error-reporting/dedup-manager.sh list
```

**Adjust cooldown** (edit `log-monitor.sh`):

```bash
COOLDOWN_SECONDS=600  # 10 minutes instead of 5
```

---

## [CONFIG] Configuration

### Environment Variables

```bash
# Skip GitHub integration
export SKIP_GITHUB=1

# Custom cooldown
export ERROR_COOLDOWN=600

# Custom database path
export DEDUP_DB_PATH=/custom/path/issue_cache.db
```

### Disable Features

```bash
# Skip systemd service installation
./upgrade.sh --skip-services

# Skip GitHub CLI setup
./upgrade.sh --skip-github

# Skip backup
./upgrade.sh --no-backup
```

---

## [DOCS] API Reference

### `report-error.sh`

```bash
./scripts/error-reporting/report-error.sh <error_type> <message> [stack_trace]
```

**Arguments:**
- `error_type` - Type of error (e.g., "frontend_crash", "segfault")
- `message` - Error message
- `stack_trace` - Optional stack trace

**Returns:**
- JSON with issue number and status

### `dedup-manager.sh`

```bash
./scripts/error-reporting/dedup-manager.sh <command> [args]
```

**Commands:**
- `init` - Initialize database
- `query <signature>` - Query issue
- `record <sig> <type> [issue]` - Record occurrence
- `list` - List all issues
- `stats` - Show statistics

---

## [GUIDE] Best Practices

### For Developers

1. **Don't disable error reporting** - It's your debugging ally
2. **Review issues weekly** - Triage auto-reported bugs
3. **Add labels** - Help categorize issues
4. **Close duplicates** - Clean up false positives
5. **Test locally first** - Use test suite before deployment

### For Users

1. **Keep monitoring enabled** - Helps improve quality
2. **Report unique issues** - Not covered by automation
3. **Check existing issues** - Before reporting manually

---

## [INFO] Additional Resources

- [Main Documentation](DIAGNOSTIC_ANALYSIS_REPORT.md)
- [Logging System](diagnostics/LOGGING.md)
- [Testing Guide](TESTING_GUIDE.md)
- [GitHub CLI Docs](https://cli.github.com/manual/)

---

## [SUCCESS] Summary

You now have a **production-grade automated error reporting system** that:

[OK] **Automatically detects** crashes and errors
[OK] **Generates structured reports** with full context
[OK] **Creates GitHub issues** automatically
[OK] **Deduplicates** similar errors intelligently
[OK] **Rate limits** to prevent spam
[OK] **Sanitizes** sensitive information
[OK] **Monitors** logs in background
[OK] **AI-readable** format for debugging agents

**One command to rule them all:**

```bash
./upgrade.sh
```

---

*Last updated: 2026-05-24*
*xKOR_3RR0R Error Reporting System v3.0.0*
