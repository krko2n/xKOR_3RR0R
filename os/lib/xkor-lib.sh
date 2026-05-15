# @summary: Shared library of bash functions for OS scripts.
#!/bin/bash
# xKOR_3RR0R - Shared library
# Source this file from any script: source "$(dirname "$0")/lib/xkor-lib.sh"

RED="\e[31m"; GREEN="\e[32m"; YELLOW="\e[33m"
BLUE="\e[34m"; CYAN="\e[36m"; RESET="\e[0m"; BOLD="\e[1m"

# Canonical paths -- never change these
XKOR_INSTALL_DIR="/opt/xkor_3rr0r"
XKOR_MANIFEST_DIR="/var/lib/xkor_3rr0r"
XKOR_MANIFEST_FILE="$XKOR_MANIFEST_DIR/manifest"
XKOR_LOG_DIR="/var/log/xkor_3rr0r"
XKOR_BIN="/usr/local/bin/xkor"
XKOR_SERVICE_LOGIN="/etc/systemd/system/xkor-login.service"
XKOR_SERVICE_UI="/etc/systemd/system/xkor-ui.service"
XKOR_PLYMOUTH_DIR="/usr/share/plymouth/themes/xkor"

# Safe deletion whitelist -- ONLY paths under these prefixes can be deleted
XKOR_SAFE_PREFIXES=(
    "/opt/xkor_3rr0r"
    "/var/log/xkor_3rr0r"
    "/var/lib/xkor_3rr0r"
    "/etc/systemd/system/xkor-login.service"
    "/etc/systemd/system/xkor-ui.service"
    "/usr/share/plymouth/themes/xkor"
    "/usr/local/bin/xkor"
    "/tmp/xkor_3rr0r"
)

XKOR_CURRENT_LOG=""

log_init() {
    XKOR_CURRENT_LOG="$1"
    mkdir -p "$(dirname "$XKOR_CURRENT_LOG")"
    echo "=== xKOR_3RR0R log started $(date -Iseconds) ===" >> "$XKOR_CURRENT_LOG"
}

_log() { echo "$@" | tee -a "${XKOR_CURRENT_LOG:-/dev/null}"; }
ok()   { _log -e "${GREEN}[  OK  ]${RESET} $1"; }
info() { _log -e "${YELLOW}[ INFO ]${RESET} $1"; }
warn() { _log -e "${YELLOW}[ WARN ]${RESET} $1"; }
fail() { _log -e "${RED}[ FAIL ]${RESET} $1"; exit 1; }
step() { _log -e "${BLUE}${BOLD}[ STEP ]${RESET} $1"; }
dbg()  { [[ "${XKOR_DEBUG:-0}" == "1" ]] && _log -e "${CYAN}[ DBG  ]${RESET} $1"; }

path_is_safe() {
    local path="$1"
    [[ -z "$path" ]] && return 1
    case "$path" in
        /|/bin|/boot|/dev|/etc|/home|/lib|/lib64|/proc|/root|/run|\
        /sbin|/srv|/sys|/tmp|/usr|/usr/bin|/usr/lib|/usr/local|\
        /usr/sbin|/usr/share|/var|/var/lib|/var/log) return 1 ;;
    esac
    for prefix in "${XKOR_SAFE_PREFIXES[@]}"; do
        [[ "$path" == "$prefix" || "$path" == "$prefix/"* ]] && return 0
    done
    return 1
}

safe_delete() {
    local path="$1"
    [[ -z "$path" ]] && return 0
    if ! path_is_safe "$path"; then
        warn "SAFETY: refusing to delete: $path"
        return 1
    fi
    if [[ -L "$path" ]]; then rm -f "$path"
    elif [[ -f "$path" ]]; then rm -f "$path"
    fi
    return 0
}

safe_delete_dir() {
    local path="$1"
    [[ -z "$path" ]] && return 0
    if ! path_is_safe "$path"; then
        warn "SAFETY: refusing to delete dir: $path"
        return 1
    fi
    [[ -d "$path" ]] && rm -rf "$path" || true
    return 0
}