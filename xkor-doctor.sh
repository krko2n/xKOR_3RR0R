#!/usr/bin/env bash
#
# xKOR_3RR0R - System Diagnostics Tool
# Version: 2.0.0-beta.2
#
# Checks system health and dependencies
# Usage: ./xkor-doctor.sh [--fix] [--verbose]
#

set -e
set -o pipefail

# ==============================================================================
# CONFIGURATION
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

# Options
OPT_FIX=false
OPT_VERBOSE=false

# Results
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNED=0

# ==============================================================================
# COLORS
# ==============================================================================

if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    DIM='\033[2m'
    RESET='\033[0m'
    CHECK='✓'
    CROSS='✗'
    WARN='⚠'
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; CYAN=''; BOLD=''; DIM=''; RESET=''
    CHECK='OK'
    CROSS='FAIL'
    WARN='WARN'
fi

# ==============================================================================
# LOGGING
# ==============================================================================

check_pass() {
    echo -e "${GREEN}${CHECK}${RESET} $*"
    ((CHECKS_PASSED++))
}

check_fail() {
    echo -e "${RED}${CROSS}${RESET} $*"
    ((CHECKS_FAILED++))
}

check_warn() {
    echo -e "${YELLOW}${WARN}${RESET} $*"
    ((CHECKS_WARNED++))
}

log_info() {
    echo -e "  ${BLUE}→${RESET} $*"
}

log_verbose() {
    [[ "$OPT_VERBOSE" == "true" ]] && echo -e "  ${DIM}$*${RESET}"
}

section() {
    echo -e "\n${BOLD}${CYAN}$*${RESET}"
}

# ==============================================================================
# UTILITY
# ==============================================================================

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

get_version() {
    local cmd="$1"
    case "$cmd" in
        rustc)
            rustc --version 2>/dev/null | awk '{print $2}'
            ;;
        node)
            node --version 2>/dev/null | sed 's/v//'
            ;;
        npm)
            npm --version 2>/dev/null
            ;;
        cargo)
            cargo --version 2>/dev/null | awk '{print $2}'
            ;;
        git)
            git --version 2>/dev/null | awk '{print $3}'
            ;;
        *)
            $cmd --version 2>/dev/null | head -1
            ;;
    esac
}

# ==============================================================================
# CHECKS
# ==============================================================================

check_system() {
    section "System Information"

    # OS
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        check_pass "OS: $PRETTY_NAME"
        log_verbose "ID: $ID"
        log_verbose "Version: ${VERSION_ID:-unknown}"
    else
        check_fail "Cannot detect OS (/etc/os-release missing)"
    fi

    # Kernel
    local kernel=$(uname -r)
    check_pass "Kernel: $kernel"

    # Architecture
    local arch=$(uname -m)
    if [[ "$arch" == "x86_64" ]]; then
        check_pass "Architecture: $arch"
    else
        check_warn "Architecture: $arch (untested)"
    fi
}

check_core_tools() {
    section "Core Tools"

    # Git
    if command_exists git; then
        local version=$(get_version git)
        check_pass "Git: $version"
    else
        check_fail "Git: not found"
    fi

    # Curl
    if command_exists curl; then
        check_pass "curl: installed"
    else
        check_warn "curl: not found"
    fi

    # Wget
    if command_exists wget; then
        check_pass "wget: installed"
    else
        check_warn "wget: not found"
    fi
}

check_rust() {
    section "Rust Toolchain"

    # Rustc
    if command_exists rustc; then
        local version=$(get_version rustc)
        check_pass "rustc: $version"
    else
        check_fail "rustc: not found"
        log_info "Install: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        return
    fi

    # Cargo
    if command_exists cargo; then
        local version=$(get_version cargo)
        check_pass "cargo: $version"
    else
        check_fail "cargo: not found"
    fi

    # Rustup
    if command_exists rustup; then
        check_pass "rustup: installed"
        log_verbose "Toolchain: $(rustup show active-toolchain 2>/dev/null | awk '{print $1}')"
    else
        check_warn "rustup: not found"
    fi
}

check_nodejs() {
    section "Node.js Environment"

    # Node
    if command_exists node; then
        local version=$(get_version node)
        local major=$(echo "$version" | cut -d. -f1)

        if [[ "$major" -ge 18 ]]; then
            check_pass "Node.js: $version"
        else
            check_fail "Node.js: $version (need 18+)"
        fi
    else
        check_fail "Node.js: not found"
        log_info "Install Node.js 18+ from https://nodejs.org/"
        return
    fi

    # npm
    if command_exists npm; then
        local version=$(get_version npm)
        check_pass "npm: $version"
    else
        check_fail "npm: not found"
    fi

    # pnpm
    if command_exists pnpm; then
        local version=$(get_version pnpm)
        check_pass "pnpm: $version"
    else
        log_verbose "pnpm: not found (optional)"
    fi

    # bun
    if command_exists bun; then
        local version=$(get_version bun)
        check_pass "bun: $version"
    else
        log_verbose "bun: not found (optional)"
    fi
}

check_tauri_deps() {
    section "Tauri Dependencies"

    # Detect package manager
    if command_exists dpkg; then
        PKG_CHECK="dpkg -l"
    elif command_exists pacman; then
        PKG_CHECK="pacman -Q"
    elif command_exists rpm; then
        PKG_CHECK="rpm -q"
    else
        check_warn "Cannot detect package manager"
        return
    fi

    # Check WebKitGTK
    if $PKG_CHECK | grep -q webkit2gtk; then
        check_pass "WebKitGTK: installed"
    else
        check_fail "WebKitGTK: not found"
        log_info "Install WebKitGTK 4.1 for your distribution"
    fi

    # Check GTK
    if $PKG_CHECK | grep -q gtk3; then
        check_pass "GTK3: installed"
    else
        check_fail "GTK3: not found"
    fi

    # Check build tools
    if command_exists gcc; then
        check_pass "GCC: installed"
    else
        check_fail "GCC: not found"
    fi

    if command_exists make; then
        check_pass "Make: installed"
    else
        check_fail "Make: not found"
    fi

    if command_exists pkg-config; then
        check_pass "pkg-config: installed"
    else
        check_fail "pkg-config: not found"
    fi
}

check_project() {
    section "Project Status"

    cd "$PROJECT_ROOT"

    # Git repo
    if git rev-parse --git-dir >/dev/null 2>&1; then
        local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
        local commit=$(git rev-parse --short HEAD 2>/dev/null)
        check_pass "Git repository: $branch ($commit)"
    else
        check_fail "Not a Git repository"
    fi

    # package.json
    if [[ -f package.json ]]; then
        local version=$(grep '"version"' package.json | head -1 | sed 's/.*"\([0-9][^"]*\)".*/\1/')
        check_pass "package.json: v$version"
    else
        check_fail "package.json: not found"
    fi

    # Cargo.toml
    if [[ -f src-tauri/Cargo.toml ]]; then
        local version=$(grep '^version' src-tauri/Cargo.toml | head -1 | sed 's/.*"\([^"]*\)".*/\1/')
        check_pass "Cargo.toml: v$version"
    else
        check_fail "Cargo.toml: not found"
    fi

    # node_modules
    if [[ -d node_modules ]]; then
        check_pass "node_modules: present"
    else
        check_warn "node_modules: missing (run: npm install)"
    fi

    # Binary
    if [[ -f src-tauri/target/release/xkor-3rr0r ]]; then
        check_pass "Binary: built (release)"
    elif [[ -f src-tauri/target/debug/xkor-3rr0r ]]; then
        check_pass "Binary: built (debug)"
    else
        check_warn "Binary: not built (run: cargo build --release)"
    fi
}

check_installation() {
    section "Installation Status"

    # Launcher
    if [[ -f /usr/local/bin/xkor ]]; then
        check_pass "Launcher: /usr/local/bin/xkor"
    else
        check_warn "Launcher: not installed"
    fi

    # Desktop entry
    local desktop="${XDG_DATA_HOME:-$HOME/.local/share}/applications/xkor_3rr0r.desktop"
    if [[ -f "$desktop" ]]; then
        check_pass "Desktop entry: installed"
    else
        check_warn "Desktop entry: not installed"
    fi

    # Config
    local config="$HOME/.config/xkor_3rr0r"
    if [[ -d "$config" ]]; then
        check_pass "Config directory: $config"
    else
        check_warn "Config directory: not found"
    fi

    # OS Mode
    if [[ -f /etc/systemd/system/xkor-login.service ]]; then
        check_pass "OS Mode: installed"
        if systemctl is-active --quiet xkor-login.service; then
            log_info "Service: running"
        else
            log_info "Service: stopped"
        fi
    else
        log_verbose "OS Mode: not installed"
    fi
}

# ==============================================================================
# FIXES
# ==============================================================================

fix_permissions() {
    section "Fixing Permissions"

    find "$PROJECT_ROOT" -name "*.sh" -type f -exec chmod +x {} \;
    check_pass "Made shell scripts executable"
}

fix_rust() {
    section "Fixing Rust"

    if ! command_exists rustc; then
        log_info "Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
        check_pass "Rust installed"
    fi
}

fix_dependencies() {
    section "Fixing Dependencies"

    cd "$PROJECT_ROOT"

    if [[ ! -d node_modules ]]; then
        log_info "Installing npm dependencies..."
        npm install
        check_pass "npm dependencies installed"
    fi
}

# ==============================================================================
# MAIN
# ==============================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --fix)
                OPT_FIX=true
                ;;
            -v|--verbose)
                OPT_VERBOSE=true
                ;;
            -h|--help)
                cat <<EOF
xKOR_3RR0R System Diagnostics

Usage: $0 [OPTIONS]

OPTIONS:
    --fix           Attempt to fix detected issues
    -v, --verbose   Show verbose output
    -h, --help      Show this help

DESCRIPTION:
    Checks system health and dependencies for xKOR_3RR0R.
    Reports issues and suggests fixes.

EXAMPLES:
    ./xkor-doctor.sh
    ./xkor-doctor.sh --fix
    ./xkor-doctor.sh --verbose

EOF
                exit 0
                ;;
            *)
                echo -e "${RED}Unknown option: $1${RESET}" >&2
                exit 1
                ;;
        esac
        shift
    done
}

print_banner() {
    cat <<'EOF'
    ╔═══════════════════════════════════════════════════════════╗
    ║                                                           ║
    ║           xKOR_3RR0R SYSTEM DIAGNOSTICS                   ║
    ║                                                           ║
    ╚═══════════════════════════════════════════════════════════╝

EOF
}

print_summary() {
    echo
    section "Summary"

    local total=$((CHECKS_PASSED + CHECKS_FAILED + CHECKS_WARNED))

    echo -e "${GREEN}${CHECK} Passed:${RESET} $CHECKS_PASSED"
    echo -e "${RED}${CROSS} Failed:${RESET} $CHECKS_FAILED"
    echo -e "${YELLOW}${WARN} Warnings:${RESET} $CHECKS_WARNED"
    echo -e "${BOLD}Total:${RESET} $total"

    echo

    if [[ $CHECKS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}${BOLD}✓ System is healthy!${RESET}"
        echo -e "You can install xKOR_3RR0R with: ${CYAN}./install.sh${RESET}"
    else
        echo -e "${RED}${BOLD}✗ Issues detected${RESET}"
        if [[ "$OPT_FIX" == "false" ]]; then
            echo -e "Run with ${CYAN}--fix${RESET} to attempt automatic fixes"
        fi
    fi

    echo
}

main() {
    parse_arguments "$@"
    print_banner

    # Run checks
    check_system
    check_core_tools
    check_rust
    check_nodejs
    check_tauri_deps
    check_project
    check_installation

    # Apply fixes if requested
    if [[ "$OPT_FIX" == "true" && $CHECKS_FAILED -gt 0 ]]; then
        echo
        section "Applying Fixes"
        fix_permissions
        fix_rust
        fix_dependencies
    fi

    # Summary
    print_summary

    # Exit code
    if [[ $CHECKS_FAILED -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
}

main "$@"
