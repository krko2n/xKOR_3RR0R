#!/bin/bash
# @summary: Removes xKOR_3RR0R OS Mode: disables service, deletes /opt/xkor_3rr0r.
# xKOR_3RR0R - Uninstaller
# Usage: sudo bash os/uninstall.sh [--remove-logs]
# Or: sudo xkor uninstall

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/xkor-lib.sh"
source "$SCRIPT_DIR/lib/manifest.sh"
source "$SCRIPT_DIR/lib/cleanup.sh"

[[ $EUID -ne 0 ]] && fail "Run as root"

mkdir -p "$XKOR_LOG_DIR"
log_init "$XKOR_LOG_DIR/uninstall_$(date +%Y-%m-%d_%H-%M-%S).log"

echo -e "${BLUE}=== xKOR_3RR0R Uninstaller ===${RESET}"
manifest_exists && ok "Manifest found -- precise cleanup" || warn "No manifest -- fallback cleanup"

REMOVE_LOGS=0
[[ "$1" == "--remove-logs" ]] && REMOVE_LOGS=1

run_cleanup "$REMOVE_LOGS"
ok "xKOR_3RR0R fully uninstalled"
[[ "$REMOVE_LOGS" == "0" ]] && info "Logs kept at $XKOR_LOG_DIR"