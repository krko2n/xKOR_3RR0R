#!/usr/bin/env bash
#
# xKOR_3RR0R - Automatic Crash Logger
# Captures crashes, logs system state, commits to git
#

set -euo pipefail

# ==============================================================================
# CONFIGURATION
# ==============================================================================

PROJECT_ROOT="${PROJECT_ROOT:-/opt/xkor_3rr0r}"
DIAG_DIR="$PROJECT_ROOT/diagnostics"
CRASH_DIR="$DIAG_DIR/crashes"
ERROR_DIR="$DIAG_DIR/errors"
LOG_DIR="$DIAG_DIR/logs"

TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
CRASH_LOG="$CRASH_DIR/${TIMESTAMP}_crash.log"
ERROR_LOG="$ERROR_DIR/${TIMESTAMP}_error.log"

# ==============================================================================
# LOGGING
# ==============================================================================

log_section() {
    echo "================================================================================" | tee -a "$1"
    echo "  $2" | tee -a "$1"
    echo "================================================================================" | tee -a "$1"
    echo "" | tee -a "$1"
}

log_command() {
    local logfile="$1"
    local description="$2"
    shift 2

    echo ">>> $description" | tee -a "$logfile"
    echo "\$ $*" | tee -a "$logfile"
    "$@" 2>&1 | tee -a "$logfile" || echo "(command failed with exit code $?)" | tee -a "$logfile"
    echo "" | tee -a "$logfile"
}

# ==============================================================================
# CRASH CAPTURE
# ==============================================================================

capture_crash() {
    local crash_type="${1:-unknown}"
    local crash_message="${2:-No message provided}"

    mkdir -p "$CRASH_DIR"

    log_section "$CRASH_LOG" "xKOR_3RR0R CRASH REPORT"

    echo "Timestamp: $TIMESTAMP" | tee -a "$CRASH_LOG"
    echo "Crash Type: $crash_type" | tee -a "$CRASH_LOG"
    echo "Message: $crash_message" | tee -a "$CRASH_LOG"
    echo "" | tee -a "$CRASH_LOG"

    log_section "$CRASH_LOG" "SYSTEM INFORMATION"
    log_command "$CRASH_LOG" "Kernel version" uname -a
    log_command "$CRASH_LOG" "Distribution" cat /etc/os-release
    log_command "$CRASH_LOG" "Uptime" uptime
    log_command "$CRASH_LOG" "Memory" free -h
    log_command "$CRASH_LOG" "Disk usage" df -h

    log_section "$CRASH_LOG" "USER SESSION STATE"
    log_command "$CRASH_LOG" "Current user" id
    log_command "$CRASH_LOG" "Environment variables" env
    log_command "$CRASH_LOG" "Active sessions" loginctl list-sessions
    log_command "$CRASH_LOG" "User runtime directory" ls -la /run/user/1000 || echo "Directory does not exist"

    log_section "$CRASH_LOG" "COMPOSITOR STATE"
    log_command "$CRASH_LOG" "Hyprland version" hyprland --version || echo "Hyprland not found"
    log_command "$CRASH_LOG" "Running compositors" ps aux | grep -E "(hyprland|Xorg|startx)" || echo "No compositors found"
    log_command "$CRASH_LOG" "Hyprland sockets" ls -la /run/user/1000/hypr/ || echo "Hyprland runtime dir missing"
    log_command "$CRASH_LOG" "Display environment" env | grep -E "(DISPLAY|WAYLAND|XDG_)"

    log_section "$CRASH_LOG" "SYSTEMD SERVICE STATE"
    log_command "$CRASH_LOG" "xkor-login service status" systemctl status xkor-login.service
    log_command "$CRASH_LOG" "xkor-login service journal (last 50 lines)" journalctl -u xkor-login.service -n 50 --no-pager
    log_command "$CRASH_LOG" "Failed units" systemctl --failed

    log_section "$CRASH_LOG" "PROCESS STATE"
    log_command "$CRASH_LOG" "xKOR processes" ps aux | grep xkor || echo "No xKOR processes"
    log_command "$CRASH_LOG" "Tauri processes" ps aux | grep tauri || echo "No Tauri processes"
    log_command "$CRASH_LOG" "Node processes" ps aux | grep node || echo "No Node processes"

    log_section "$CRASH_LOG" "FILE PERMISSIONS"
    log_command "$CRASH_LOG" "Project directory" ls -la "$PROJECT_ROOT"
    log_command "$CRASH_LOG" "OS directory" ls -la "$PROJECT_ROOT/os"
    log_command "$CRASH_LOG" "Binary permissions" ls -la "$PROJECT_ROOT/src-tauri/target/release/" || echo "Binary not found"

    log_section "$CRASH_LOG" "RECENT LOGS"
    if [[ -d "$LOG_DIR/compositor" ]]; then
        log_command "$CRASH_LOG" "Recent compositor logs" tail -n 50 "$LOG_DIR/compositor"/*.log 2>/dev/null || echo "No compositor logs"
    fi
    if [[ -d "$LOG_DIR/runtime" ]]; then
        log_command "$CRASH_LOG" "Recent runtime logs" tail -n 50 "$LOG_DIR/runtime"/*.log 2>/dev/null || echo "No runtime logs"
    fi

    log_section "$CRASH_LOG" "STACK TRACE"
    if [[ -n "${BASH_SOURCE:-}" ]]; then
        echo "Bash stack trace:" | tee -a "$CRASH_LOG"
        for ((i=0; i<${#BASH_SOURCE[@]}; i++)); do
            echo "  $i: ${BASH_SOURCE[$i]:-unknown}:${BASH_LINENO[$i]:-0} in ${FUNCNAME[$i]:-main}" | tee -a "$CRASH_LOG"
        done
    fi

    echo "" | tee -a "$CRASH_LOG"
    echo "Crash log saved: $CRASH_LOG" | tee -a "$CRASH_LOG"
}

# ==============================================================================
# GIT AUTO-COMMIT
# ==============================================================================

commit_crash_report() {
    cd "$PROJECT_ROOT"

    # Check if diagnostics/ is in .gitignore
    if grep -q "^diagnostics/" .gitignore 2>/dev/null; then
        echo "Removing diagnostics/ from .gitignore..."
        sed -i '/^diagnostics\//d' .gitignore
    fi

    # Stage crash report
    git add "$CRASH_LOG" 2>/dev/null || true

    # Commit with structured message
    if git diff --cached --quiet 2>/dev/null; then
        echo "No changes to commit (crash log may already be tracked)"
    else
        local commit_msg="crash: $TIMESTAMP - $1

Automatic crash report generated by diagnostics/crash-logger.sh

Crash type: $1
Timestamp: $TIMESTAMP
Log: diagnostics/crashes/${TIMESTAMP}_crash.log

This is an automated diagnostic commit.
Review the log file for full system state at crash time."

        git commit -m "$commit_msg" 2>&1 || echo "Git commit failed (not fatal)"
        echo "Crash report committed to git: $TIMESTAMP"
    fi
}

# ==============================================================================
# ERROR CAPTURE
# ==============================================================================

capture_error() {
    local error_type="${1:-unknown}"
    local error_message="${2:-No message provided}"
    local stack_trace="${3:-}"

    mkdir -p "$ERROR_DIR"

    {
        echo "================================================================================"
        echo "  xKOR_3RR0R ERROR REPORT"
        echo "================================================================================"
        echo ""
        echo "Timestamp: $TIMESTAMP"
        echo "Error Type: $error_type"
        echo "Message: $error_message"
        echo ""

        if [[ -n "$stack_trace" ]]; then
            echo "Stack Trace:"
            echo "$stack_trace"
            echo ""
        fi

        echo "Environment:"
        env | grep -E "(XDG_|DISPLAY|WAYLAND|PATH)" || true
        echo ""

        echo "Recent journal entries:"
        journalctl -n 20 --no-pager || true
    } > "$ERROR_LOG"

    echo "Error log saved: $ERROR_LOG"
}

# ==============================================================================
# CLEANUP OLD LOGS
# ==============================================================================

cleanup_old_logs() {
    local days_to_keep=7

    echo "Cleaning up logs older than $days_to_keep days..."

    find "$CRASH_DIR" -name "*.log" -mtime +"$days_to_keep" -delete 2>/dev/null || true
    find "$ERROR_DIR" -name "*.log" -mtime +"$days_to_keep" -delete 2>/dev/null || true
    find "$LOG_DIR" -name "*.log" -mtime +"$days_to_keep" -delete 2>/dev/null || true

    echo "Cleanup complete"
}

# ==============================================================================
# MAIN
# ==============================================================================

main() {
    local action="${1:-help}"

    case "$action" in
        crash)
            capture_crash "${2:-unknown}" "${3:-No message}"
            commit_crash_report "${2:-unknown}"
            ;;
        error)
            capture_error "${2:-unknown}" "${3:-No message}" "${4:-}"
            ;;
        cleanup)
            cleanup_old_logs
            ;;
        help|*)
            cat <<EOF
xKOR_3RR0R Crash Logger

Usage: $0 <action> [args]

ACTIONS:
    crash <type> <message>       Capture full crash report and commit to git
    error <type> <message>       Capture error (no system state dump)
    cleanup                      Remove logs older than 7 days
    help                         Show this help

EXAMPLES:
    $0 crash "compositor" "Hyprland socket init failed"
    $0 error "authentication" "Login failed for user"
    $0 cleanup

LOGS:
    Crashes: $CRASH_DIR
    Errors:  $ERROR_DIR
    Runtime: $LOG_DIR

EOF
            ;;
    esac
}

main "$@"
