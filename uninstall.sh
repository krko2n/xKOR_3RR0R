#!/usr/bin/env bash
#
# xKOR_3RR0R - Uninstall Script
# Version: 2.0.0-beta.2
#
# Safely removes xKOR_3RR0R from system
# Usage: ./uninstall.sh [--purge] [--keep-config]
#

set -e
set -o pipefail

# ==============================================================================
# CONFIGURATION
# ==============================================================================

# Directories
INSTALL_DIR="/opt/xkor_3rr0r"
CONFIG_DIR="$HOME/.config/xkor_3rr0r"
DATA_DIR="$HOME/.local/share/xkor_3rr0r"
CACHE_DIR="$HOME/.cache/xkor_3rr0r"
LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/xkor_3rr0r"

# System files
LAUNCHER="/usr/local/bin/xkor"
DESKTOP_ENTRY="${XDG_DATA_HOME:-$HOME/.local/share}/applications/xkor_3rr0r.desktop"
SYSTEMD_SERVICE="/etc/systemd/system/xkor-login.service"

# Options
OPT_PURGE=false
OPT_KEEP_CONFIG=false
OPT_FORCE=false

# ==============================================================================
# COLORS
# ==============================================================================

if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    RESET='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; BOLD=''; RESET=''
fi

log_info() {
    echo -e "${BLUE}[INFO]${RESET} $*" >&2
}

log_success() {
    echo -e "${GREEN}[DONE]${RESET} $*" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${RESET} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${RESET} $*" >&2
}

log_step() {
    echo -e "\n${BOLD}${BLUE}▶${RESET} ${BOLD}$*${RESET}" >&2
}

# ==============================================================================
# UTILITY
# ==============================================================================

ask_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    local answer

    if [[ "$OPT_FORCE" == "true" ]]; then
        [[ "$default" == "y" ]]
        return
    fi

    if [[ "$default" == "y" ]]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi

    read -r -p "$(echo -e "${YELLOW}?${RESET} $prompt")" answer
    answer="${answer:-$default}"
    [[ "$answer" =~ ^[Yy]$ ]]
}

remove_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        rm -f "$file" && log_success "Removed: $file"
    fi
}

remove_dir() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        rm -rf "$dir" && log_success "Removed: $dir"
    fi
}

# ==============================================================================
# UNINSTALL
# ==============================================================================

stop_services() {
    log_step "Stopping services..."

    # Stop systemd service if running
    if systemctl is-active --quiet xkor-login.service 2>/dev/null; then
        log_info "Stopping xkor-login service..."
        sudo systemctl stop xkor-login.service || log_warn "Failed to stop service"
        sudo systemctl disable xkor-login.service || log_warn "Failed to disable service"
    fi

    log_success "Services stopped"
}

remove_system_files() {
    log_step "Removing system files..."

    local needs_sudo=""
    if [[ $EUID -ne 0 ]]; then
        needs_sudo="sudo"
    fi

    # Remove launcher
    if [[ -f "$LAUNCHER" ]]; then
        $needs_sudo rm -f "$LAUNCHER" && log_success "Removed launcher"
    fi

    # Remove systemd service
    if [[ -f "$SYSTEMD_SERVICE" ]]; then
        $needs_sudo rm -f "$SYSTEMD_SERVICE" && log_success "Removed systemd service"
        $needs_sudo systemctl daemon-reload
    fi

    # Remove desktop entry
    remove_file "$DESKTOP_ENTRY"

    # Remove OS mode install
    if [[ -d "$INSTALL_DIR" ]]; then
        if ask_yes_no "Remove OS Mode installation ($INSTALL_DIR)?" "y"; then
            $needs_sudo rm -rf "$INSTALL_DIR" && log_success "Removed OS Mode files"
        fi
    fi

    log_success "System files removed"
}

remove_user_files() {
    log_step "Removing user files..."

    # Always remove cache
    remove_dir "$CACHE_DIR"

    # Remove data
    if [[ "$OPT_PURGE" == "true" ]] || [[ "$OPT_KEEP_CONFIG" == "false" ]]; then
        remove_dir "$DATA_DIR"
    fi

    # Remove config
    if [[ "$OPT_PURGE" == "true" ]]; then
        remove_dir "$CONFIG_DIR"
        log_success "Purged all user data"
    elif [[ "$OPT_KEEP_CONFIG" == "false" ]]; then
        remove_dir "$CONFIG_DIR"
    else
        log_info "Kept configs: $CONFIG_DIR"
    fi

    # Remove logs
    if [[ "$OPT_PURGE" == "true" ]]; then
        remove_dir "$LOG_DIR"
    fi

    log_success "User files removed"
}

# ==============================================================================
# MAIN
# ==============================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --purge)
                OPT_PURGE=true
                ;;
            --keep-config)
                OPT_KEEP_CONFIG=true
                ;;
            --force)
                OPT_FORCE=true
                ;;
            -h|--help)
                cat <<EOF
xKOR_3RR0R Uninstall Script

Usage: $0 [OPTIONS]

OPTIONS:
    --purge         Remove all data including configs and logs
    --keep-config   Keep configuration files
    --force         Skip confirmation prompts
    -h, --help      Show this help

EXAMPLES:
    ./uninstall.sh
    ./uninstall.sh --purge
    ./uninstall.sh --keep-config

WHAT GETS REMOVED:
    - Launcher: /usr/local/bin/xkor
    - Desktop entry
    - Systemd service (OS Mode)
    - Cache: ~/.cache/xkor_3rr0r
    - Data: ~/.local/share/xkor_3rr0r (unless --keep-config)
    - Config: ~/.config/xkor_3rr0r (unless --keep-config or --purge)
    - Logs: ~/.local/state/xkor_3rr0r (only with --purge)
    - OS Mode files: /opt/xkor_3rr0r (if present)

EOF
                exit 0
                ;;
            *)
                log_error "Unknown option: $1 (use --help for usage)"
                exit 1
                ;;
        esac
        shift
    done

    # Validate options
    if [[ "$OPT_PURGE" == "true" && "$OPT_KEEP_CONFIG" == "true" ]]; then
        log_error "Cannot use --purge and --keep-config together"
        exit 1
    fi
}

print_banner() {
    cat <<'EOF'
    ╔═══════════════════════════════════════════════════════════╗
    ║                                                           ║
    ║           xKOR_3RR0R UNINSTALL UTILITY                    ║
    ║                                                           ║
    ╚═══════════════════════════════════════════════════════════╝

EOF
}

main() {
    parse_arguments "$@"
    print_banner

    # Confirm
    echo -e "${YELLOW}This will remove xKOR_3RR0R from your system.${RESET}"
    if [[ "$OPT_PURGE" == "true" ]]; then
        echo -e "${RED}⚠ PURGE MODE: All data including configs will be removed!${RESET}"
    elif [[ "$OPT_KEEP_CONFIG" == "true" ]]; then
        echo -e "${YELLOW}Configs will be kept for future reinstalls.${RESET}"
    fi
    echo

    if ! ask_yes_no "Continue with uninstall?" "n"; then
        log_info "Uninstall cancelled"
        exit 0
    fi

    # Uninstall
    stop_services
    remove_system_files
    remove_user_files

    # Done
    echo
    log_success "${BOLD}xKOR_3RR0R has been uninstalled${RESET}"
    echo
    if [[ "$OPT_KEEP_CONFIG" == "true" ]]; then
        log_info "Configs preserved in: $CONFIG_DIR"
    fi
    echo
}

main "$@"
