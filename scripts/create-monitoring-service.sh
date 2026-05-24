#!/usr/bin/env bash
#
# Creates background monitoring service
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MONITORING_DIR="$PROJECT_ROOT/.github/monitoring"

mkdir -p "$MONITORING_DIR"

# ==============================================================================
# LOG MONITOR DAEMON
# ==============================================================================

cat > "$MONITORING_DIR/log-monitor.sh" << 'SHEOF'
#!/usr/bin/env bash
#
# xKOR_3RR0R - Log Monitor Daemon
# Monitors logs for errors and reports them automatically
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
ERROR_REPORTING="$PROJECT_ROOT/scripts/error-reporting"

# Configuration
WATCH_PATTERNS=(
    "ERROR"
    "FATAL"
    "PANIC"
    "EXCEPTION"
    "SEGFAULT"
    "SIGSEGV"
    "core dumped"
)

COOLDOWN_SECONDS=300  # 5 minutes between reports for same error
LAST_REPORT_FILE="/tmp/xkor_last_report_time"

log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [MONITOR] $*"
}

should_report() {
    local signature="$1"

    # Check cooldown
    if [[ -f "$LAST_REPORT_FILE" ]]; then
        local last_time=$(cat "$LAST_REPORT_FILE")
        local current_time=$(date +%s)
        local diff=$((current_time - last_time))

        if [[ $diff -lt $COOLDOWN_SECONDS ]]; then
            log_info "Cooldown active, skipping report"
            return 1
        fi
    fi

    return 0
}

record_report() {
    date +%s > "$LAST_REPORT_FILE"
}

check_diagnostics_logs() {
    local logs_dir="$PROJECT_ROOT/diagnostics/logs"

    if [[ ! -d "$logs_dir" ]]; then
        return
    fi

    # Find recent log files (modified in last minute)
    local recent_logs=$(find "$logs_dir" -name "*.log" -mmin -1 2>/dev/null || true)

    for log_file in $recent_logs; do
        for pattern in "${WATCH_PATTERNS[@]}"; do
            if grep -qi "$pattern" "$log_file" 2>/dev/null; then
                local error_line=$(grep -i "$pattern" "$log_file" | tail -1)
                log_info "Found pattern '$pattern' in $log_file"

                if should_report "$pattern"; then
                    bash "$ERROR_REPORTING/report-error.sh" \
                        "log_error" \
                        "$error_line" \
                        "$(tail -20 "$log_file")" &
                    record_report
                fi

                break
            fi
        done
    done
}

check_journald() {
    if ! command -v journalctl >/dev/null 2>&1; then
        return
    fi

    # Check xkor-login service
    local journal_errors=$(journalctl -u xkor-login --since "1 minute ago" --no-pager 2>/dev/null | \
        grep -iE "ERROR|FATAL|PANIC|EXCEPTION" || true)

    if [[ -n "$journal_errors" ]]; then
        local first_error=$(echo "$journal_errors" | head -1)
        log_info "Found error in systemd journal"

        if should_report "journald_error"; then
            bash "$ERROR_REPORTING/report-error.sh" \
                "systemd_error" \
                "$first_error" \
                "$journal_errors" &
            record_report
        fi
    fi
}

check_crash_reports() {
    local crash_dir="$PROJECT_ROOT/diagnostics/crashes"

    if [[ ! -d "$crash_dir" ]]; then
        return
    fi

    # Find crash reports from last minute
    local recent_crashes=$(find "$crash_dir" -name "*.log" -mmin -1 2>/dev/null || true)

    if [[ -n "$recent_crashes" ]]; then
        for crash_file in $recent_crashes; do
            log_info "New crash report detected: $crash_file"

            if should_report "crash_$(basename "$crash_file")"; then
                local crash_type=$(grep "Crash Type:" "$crash_file" | cut -d: -f2 | xargs || echo "unknown")
                local crash_message=$(grep "Message:" "$crash_file" | cut -d: -f2 | xargs || echo "No message")

                bash "$ERROR_REPORTING/report-error.sh" \
                    "$crash_type" \
                    "$crash_message" \
                    "$(cat "$crash_file")" &
                record_report
            fi

            break
        done
    fi
}

main_loop() {
    log_info "Starting log monitor daemon"

    while true; do
        check_diagnostics_logs
        check_journald
        check_crash_reports

        # Sleep for 60 seconds between checks
        sleep 60
    done
}

main() {
    log_info "xKOR_3RR0R Log Monitor starting..."
    log_info "Watching patterns: ${WATCH_PATTERNS[*]}"

    # Create PID file
    echo $$ > /tmp/xkor_monitor.pid

    main_loop
}

# Cleanup on exit
trap 'rm -f /tmp/xkor_monitor.pid; log_info "Monitor stopped"' EXIT

main "$@"
SHEOF

chmod +x "$MONITORING_DIR/log-monitor.sh"

# ==============================================================================
# SYSTEMD SERVICE
# ==============================================================================

cat > "$MONITORING_DIR/xkor-monitor.service" << 'SERVICEEOF'
[Unit]
Description=xKOR_3RR0R Error Monitoring Service
Documentation=https://github.com/krko2n/xKOR_3RR0R
After=network.target

[Service]
Type=simple
User=%i
WorkingDirectory=/opt/xkor_3rr0r
ExecStart=/opt/xkor_3rr0r/.github/monitoring/log-monitor.sh

# Restart policy
Restart=on-failure
RestartSec=10s

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=xkor-monitor

# Resource limits
CPUQuota=10%
MemoryMax=100M

[Install]
WantedBy=multi-user.target
SERVICEEOF

# ==============================================================================
# MANUAL START SCRIPT
# ==============================================================================

cat > "$MONITORING_DIR/start-monitor.sh" << 'STARTEOF'
#!/usr/bin/env bash
#
# Manually start log monitor (for systems without systemd)
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting xKOR_3RR0R error monitor..."

# Check if already running
if [[ -f /tmp/xkor_monitor.pid ]]; then
    pid=$(cat /tmp/xkor_monitor.pid)
    if ps -p "$pid" > /dev/null 2>&1; then
        echo "Monitor already running (PID: $pid)"
        exit 0
    fi
fi

# Start in background
nohup "$SCRIPT_DIR/log-monitor.sh" > /tmp/xkor_monitor.log 2>&1 &

echo "Monitor started (PID: $!)"
echo "Log: /tmp/xkor_monitor.log"
STARTEOF

chmod +x "$MONITORING_DIR/start-monitor.sh"

# ==============================================================================
# STOP SCRIPT
# ==============================================================================

cat > "$MONITORING_DIR/stop-monitor.sh" << 'STOPEOF'
#!/usr/bin/env bash
#
# Stop log monitor
#

if [[ ! -f /tmp/xkor_monitor.pid ]]; then
    echo "Monitor not running"
    exit 0
fi

pid=$(cat /tmp/xkor_monitor.pid)

if ps -p "$pid" > /dev/null 2>&1; then
    echo "Stopping monitor (PID: $pid)..."
    kill "$pid"
    rm -f /tmp/xkor_monitor.pid
    echo "Monitor stopped"
else
    echo "Monitor not running (stale PID file)"
    rm -f /tmp/xkor_monitor.pid
fi
STOPEOF

chmod +x "$MONITORING_DIR/stop-monitor.sh"

echo "✓ Monitoring service created in: $MONITORING_DIR"
