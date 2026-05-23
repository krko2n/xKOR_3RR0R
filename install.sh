#!/usr/bin/env bash
#
# xKOR_3RR0R - Professional Installation Script
# Version: 2.0.0-beta.2
#
# One-command installation for Linux systems
# Usage: ./install.sh [--mode=app|os] [--no-audio] [--portable] [--dev]
#
# Supports: Debian, Ubuntu, Arch, Fedora, openSUSE
#

set -e
set -o pipefail

# ==============================================================================
# CONFIGURATION
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
PROJECT_VERSION=$(grep '"version"' "$PROJECT_ROOT/package.json" 2>/dev/null | head -1 | sed 's/.*"\([0-9][^"]*\)".*/\1/' || echo "2.0.0-beta.1")

# Installation mode
INSTALL_MODE="app"          # app (window) or os (fullscreen desktop replacement)
INSTALL_DIR="/opt/xkor_3rr0r"
CONFIG_DIR="$HOME/.config/xkor_3rr0r"
DATA_DIR="$HOME/.local/share/xkor_3rr0r"
CACHE_DIR="$HOME/.cache/xkor_3rr0r"

# Options
OPT_NO_AUDIO=false
OPT_PORTABLE=false
OPT_DEV_MODE=false
OPT_SKIP_BUILD=false
OPT_VERBOSE=false

# Logging
LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/xkor_3rr0r/logs"
LOG_FILE="$LOG_DIR/install_$(date +%Y%m%d_%H%M%S).log"

# ==============================================================================
# COLORS & LOGGING
# ==============================================================================

if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    MAGENTA='\033[0;35m'
    BOLD='\033[1m'
    DIM='\033[2m'
    RESET='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; CYAN=''; MAGENTA=''; BOLD=''; DIM=''; RESET=''
fi

log_raw() {
    echo -e "$@" | tee -a "$LOG_FILE" >&2
}

log_info() {
    log_raw "${BLUE}[INFO]${RESET} $*"
}

log_success() {
    log_raw "${GREEN}[DONE]${RESET} $*"
}

log_warn() {
    log_raw "${YELLOW}[WARN]${RESET} $*"
}

log_error() {
    log_raw "${RED}[ERROR]${RESET} $*"
}

log_fatal() {
    log_error "$*"
    log_error "Installation failed. Check log: $LOG_FILE"
    exit 1
}

log_step() {
    log_raw "\n${BOLD}${CYAN}▶${RESET} ${BOLD}$*${RESET}"
}

log_substep() {
    log_raw "  ${DIM}→${RESET} $*"
}

log_verbose() {
    [[ "$OPT_VERBOSE" == "true" ]] && log_raw "${DIM}[DEBUG]${RESET} $*"
}

# ==============================================================================
# UTILITY FUNCTIONS
# ==============================================================================

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

ask_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    local answer

    if [[ "$default" == "y" ]]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi

    read -r -p "$(echo -e "${YELLOW}?${RESET} $prompt")" answer
    answer="${answer:-$default}"
    [[ "$answer" =~ ^[Yy]$ ]]
}

create_directory() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir" || log_fatal "Failed to create directory: $dir"
        log_verbose "Created directory: $dir"
    fi
}

# ==============================================================================
# DISTRO DETECTION
# ==============================================================================

detect_distro() {
    log_step "Detecting Linux distribution..."

    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        DISTRO_ID="${ID:-unknown}"
        DISTRO_NAME="${PRETTY_NAME:-$ID}"
        DISTRO_VERSION="${VERSION_ID:-unknown}"
    else
        log_fatal "Cannot detect distribution (/etc/os-release missing)"
    fi

    # Detect package manager
    if command_exists apt-get; then
        PKG_MGR="apt"
        PKG_INSTALL="apt-get install -y"
        PKG_UPDATE="apt-get update"
    elif command_exists pacman; then
        PKG_MGR="pacman"
        PKG_INSTALL="pacman -S --noconfirm --needed"
        PKG_UPDATE="pacman -Sy"
    elif command_exists dnf; then
        PKG_MGR="dnf"
        PKG_INSTALL="dnf install -y"
        PKG_UPDATE="dnf check-update"
    elif command_exists zypper; then
        PKG_MGR="zypper"
        PKG_INSTALL="zypper install -y"
        PKG_UPDATE="zypper refresh"
    elif command_exists apk; then
        PKG_MGR="apk"
        PKG_INSTALL="apk add"
        PKG_UPDATE="apk update"
    else
        log_fatal "No supported package manager found (apt, pacman, dnf, zypper, apk)"
    fi

    log_success "Detected: $DISTRO_NAME ($DISTRO_ID, $PKG_MGR)"
    log_verbose "Version: $DISTRO_VERSION"
}

# ==============================================================================
# DEPENDENCY CHECKS
# ==============================================================================

check_rust() {
    log_substep "Checking Rust toolchain..."

    if ! command_exists rustc; then
        log_warn "Rust not found, installing..."
        install_rust
    fi

    local rust_version
    rust_version=$(rustc --version 2>/dev/null | awk '{print $2}')
    log_success "Rust: $rust_version"
}

install_rust() {
    if command_exists rustup; then
        rustup install stable
        rustup default stable
    else
        log_substep "Installing Rust via rustup..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
        source "$HOME/.cargo/env"
    fi

    # Verify installation
    if ! command_exists rustc; then
        log_fatal "Rust installation failed"
    fi
}

check_nodejs() {
    log_substep "Checking Node.js..."

    if ! command_exists node; then
        log_fatal "Node.js not found. Please install Node.js 18+ manually."
    fi

    local node_version
    node_version=$(node --version 2>/dev/null | sed 's/v//')
    local node_major
    node_major=$(echo "$node_version" | cut -d. -f1)

    if [[ "$node_major" -lt 18 ]]; then
        log_fatal "Node.js $node_version is too old. Need version 18+."
    fi

    log_success "Node.js: $node_version"
}

check_npm() {
    log_substep "Checking npm..."

    if ! command_exists npm; then
        log_fatal "npm not found. Install Node.js with npm included."
    fi

    local npm_version
    npm_version=$(npm --version 2>/dev/null)
    log_success "npm: $npm_version"
}

install_system_dependencies() {
    log_step "Installing system dependencies..."

    # Check if running as root
    local needs_sudo=""
    if [[ $EUID -ne 0 ]]; then
        if command_exists sudo; then
            needs_sudo="sudo"
            log_warn "Some dependencies require root. You may be prompted for password."
        else
            log_fatal "Root access required but sudo not available"
        fi
    fi

    # Update package cache
    log_substep "Updating package cache..."
    $needs_sudo $PKG_UPDATE || log_warn "Package cache update failed"

    # Base dependencies (all distros)
    local base_deps=("git" "curl" "wget" "unzip" "tar")

    # Tauri dependencies (distro-specific)
    local tauri_deps=()

    case "$PKG_MGR" in
        apt)
            tauri_deps=(
                "libwebkit2gtk-4.1-dev"
                "libgtk-3-dev"
                "libayatana-appindicator3-dev"
                "librsvg2-dev"
                "libsoup-3.0-dev"
                "libjavascriptcoregtk-4.1-dev"
                "build-essential"
                "pkg-config"
                "libssl-dev"
            )
            ;;
        pacman)
            tauri_deps=(
                "webkit2gtk-4.1"
                "gtk3"
                "libappindicator-gtk3"
                "librsvg"
                "libsoup3"
                "base-devel"
                "openssl"
            )
            ;;
        dnf)
            tauri_deps=(
                "webkit2gtk4.1-devel"
                "gtk3-devel"
                "libappindicator-gtk3-devel"
                "librsvg2-devel"
                "libsoup3-devel"
                "openssl-devel"
                "gcc"
                "gcc-c++"
                "make"
            )
            ;;
        zypper)
            tauri_deps=(
                "webkit2gtk3-devel"
                "gtk3-devel"
                "libappindicator3-1"
                "librsvg-devel"
                "libsoup-devel"
                "gcc"
                "gcc-c++"
                "make"
            )
            ;;
        apk)
            tauri_deps=(
                "webkit2gtk-dev"
                "gtk+3.0-dev"
                "libappindicator-dev"
                "librsvg-dev"
                "libsoup3-dev"
                "build-base"
            )
            ;;
    esac

    # OS Mode additional dependencies
    if [[ "$INSTALL_MODE" == "os" ]]; then
        case "$PKG_MGR" in
            apt)
                tauri_deps+=("xorg" "xinit" "plymouth" "pamtester" "unclutter")
                ;;
            pacman)
                tauri_deps+=("xorg-server" "xorg-xinit" "plymouth" "pamtester" "unclutter")
                ;;
            dnf)
                tauri_deps+=("xorg-x11-server-Xorg" "xorg-x11-xinit" "plymouth" "pam" "unclutter-xfixes")
                ;;
        esac
    fi

    # Install base dependencies
    log_substep "Installing base dependencies..."
    for dep in "${base_deps[@]}"; do
        if ! command_exists "$dep"; then
            log_verbose "Installing $dep..."
            $needs_sudo $PKG_INSTALL "$dep" || log_warn "Failed to install $dep"
        fi
    done

    # Install Tauri dependencies
    log_substep "Installing Tauri dependencies..."
    $needs_sudo $PKG_INSTALL "${tauri_deps[@]}" || log_warn "Some Tauri dependencies failed to install"

    log_success "System dependencies installed"
}

# ==============================================================================
# BUILD PROCESS
# ==============================================================================

install_frontend_dependencies() {
    log_step "Installing frontend dependencies..."

    cd "$PROJECT_ROOT"

    if [[ -f package-lock.json ]]; then
        log_substep "Using npm..."
        npm ci || npm install
    elif [[ -f pnpm-lock.yaml ]]; then
        if ! command_exists pnpm; then
            npm install -g pnpm
        fi
        log_substep "Using pnpm..."
        pnpm install
    elif [[ -f bun.lockb ]]; then
        if ! command_exists bun; then
            curl -fsSL https://bun.sh/install | bash
        fi
        log_substep "Using bun..."
        bun install
    else
        log_substep "Using npm..."
        npm install
    fi

    log_success "Frontend dependencies installed"
}

build_rust_backend() {
    log_step "Building Rust backend..."

    cd "$PROJECT_ROOT/src-tauri"

    # Clean previous build if requested
    if [[ "$OPT_SKIP_BUILD" != "true" ]]; then
        if ask_yes_no "Clean previous build artifacts?" "n"; then
            log_substep "Cleaning..."
            cargo clean
        fi
    fi

    # Build release binary
    log_substep "Compiling (this may take several minutes)..."
    log_info "Tip: Grab a coffee ☕ - first build can take 5-10 minutes"

    if [[ "$OPT_DEV_MODE" == "true" ]]; then
        cargo build || log_fatal "Rust build failed"
        BUILD_TARGET="debug"
    else
        cargo build --release || log_fatal "Rust build failed"
        BUILD_TARGET="release"
    fi

    local binary_path="$PROJECT_ROOT/src-tauri/target/$BUILD_TARGET/xkor-3rr0r"
    if [[ ! -f "$binary_path" ]]; then
        log_fatal "Binary not found at: $binary_path"
    fi

    log_success "Rust backend built: $binary_path"
}

# ==============================================================================
# INSTALLATION
# ==============================================================================

install_app_mode() {
    log_step "Installing App Mode..."

    # Create directories
    create_directory "$CONFIG_DIR"
    create_directory "$DATA_DIR"
    create_directory "$CACHE_DIR"

    # Copy default configs
    if [[ -d "$PROJECT_ROOT/config" ]]; then
        log_substep "Copying default configs..."
        cp -r "$PROJECT_ROOT/config" "$CONFIG_DIR/" 2>/dev/null || true
    fi

    # Copy themes
    if [[ -d "$PROJECT_ROOT/assets/themes" ]]; then
        log_substep "Installing themes..."
        create_directory "$DATA_DIR/themes"
        cp -r "$PROJECT_ROOT/assets/themes"/* "$DATA_DIR/themes/" 2>/dev/null || true
    fi

    # Create launcher script
    log_substep "Creating launcher..."
    local launcher="/usr/local/bin/xkor"
    local needs_sudo=""
    [[ $EUID -ne 0 ]] && needs_sudo="sudo"

    $needs_sudo tee "$launcher" > /dev/null <<EOF
#!/bin/bash
cd "$PROJECT_ROOT"
exec "$PROJECT_ROOT/src-tauri/target/release/xkor-3rr0r" "\$@"
EOF

    $needs_sudo chmod +x "$launcher"

    # Create desktop entry
    if [[ -n "$XDG_DATA_HOME" ]] || [[ -d "$HOME/.local/share/applications" ]]; then
        log_substep "Creating desktop entry..."
        local desktop_dir="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
        create_directory "$desktop_dir"

        cat > "$desktop_dir/xkor_3rr0r.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=xKOR_3RR0R
Comment=Cyberpunk System Dashboard
Exec=/usr/local/bin/xkor
Icon=$PROJECT_ROOT/logo.png
Terminal=false
Categories=System;Monitor;
Keywords=system;monitor;terminal;cyberpunk;
EOF

        chmod +x "$desktop_dir/xkor_3rr0r.desktop"
    fi

    log_success "App Mode installed"
}

install_os_mode() {
    log_step "Installing OS Mode (Desktop Replacement)..."

    # Require root
    if [[ $EUID -ne 0 ]]; then
        log_fatal "OS Mode requires root. Run with sudo."
    fi

    # Delegate to os/install.sh
    log_substep "Delegating to OS installer..."
    bash "$PROJECT_ROOT/os/install.sh"
}

# ==============================================================================
# POST-INSTALL
# ==============================================================================

post_install() {
    log_step "Post-installation tasks..."

    # Fix permissions
    log_substep "Fixing permissions..."
    find "$PROJECT_ROOT" -name "*.sh" -type f -exec chmod +x {} \;

    # Create symlink to project
    if [[ "$INSTALL_MODE" == "app" ]]; then
        create_directory "$DATA_DIR"
        ln -sf "$PROJECT_ROOT" "$DATA_DIR/repo" 2>/dev/null || true
    fi

    log_success "Post-installation complete"
}

# ==============================================================================
# MAIN
# ==============================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --mode=*)
                INSTALL_MODE="${1#*=}"
                ;;
            --mode)
                INSTALL_MODE="$2"
                shift
                ;;
            --os)
                INSTALL_MODE="os"
                ;;
            --app)
                INSTALL_MODE="app"
                ;;
            --no-audio)
                OPT_NO_AUDIO=true
                ;;
            --portable)
                OPT_PORTABLE=true
                ;;
            --dev)
                OPT_DEV_MODE=true
                ;;
            --skip-build)
                OPT_SKIP_BUILD=true
                ;;
            -v|--verbose)
                OPT_VERBOSE=true
                ;;
            -h|--help)
                cat <<EOF
xKOR_3RR0R Installation Script

Usage: $0 [OPTIONS]

OPTIONS:
    --mode=MODE         Installation mode: 'app' (default) or 'os'
    --os                Shortcut for --mode=os
    --app               Shortcut for --mode=app (default)
    --no-audio          Disable audio system
    --portable          Portable mode (configs in project dir)
    --dev               Development mode (debug build)
    --skip-build        Skip cargo build (use existing binary)
    -v, --verbose       Verbose output
    -h, --help          Show this help

MODES:
    app - Run as a window application (recommended for most users)
    os  - Replace desktop environment (advanced, Arch Linux only)

EXAMPLES:
    ./install.sh
    ./install.sh --mode=app
    sudo ./install.sh --mode=os
    ./install.sh --dev --verbose

EOF
                exit 0
                ;;
            *)
                log_fatal "Unknown option: $1 (use --help for usage)"
                ;;
        esac
        shift
    done

    # Validate mode
    if [[ "$INSTALL_MODE" != "app" && "$INSTALL_MODE" != "os" ]]; then
        log_fatal "Invalid mode: $INSTALL_MODE (must be 'app' or 'os')"
    fi
}

print_banner() {
    cat <<'EOF'
    ╔═══════════════════════════════════════════════════════════╗
    ║                                                           ║
    ║              ██╗  ██╗██╗  ██╗ ██████╗ ██████╗            ║
    ║              ╚██╗██╔╝██║ ██╔╝██╔═══██╗██╔══██╗           ║
    ║               ╚███╔╝ █████╔╝ ██║   ██║██████╔╝           ║
    ║               ██╔██╗ ██╔═██╗ ██║   ██║██╔══██╗           ║
    ║              ██╔╝ ██╗██║  ██╗╚██████╔╝██║  ██║           ║
    ║              ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝           ║
    ║                                                           ║
    ║           █████╗ ██████╗ ██████╗  ██████╗ ██████╗        ║
    ║          ╚════██╗██╔══██╗██╔══██╗██╔═████╗██╔══██╗       ║
    ║           █████╔╝██████╔╝██████╔╝██║██╔██║██████╔╝       ║
    ║           ╚═══██╗██╔══██╗██╔══██╗████╔╝██║██╔══██╗       ║
    ║          ██████╔╝██║  ██║██║  ██║╚██████╔╝██║  ██║       ║
    ║          ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝       ║
    ║                                                           ║
    ║           CYBERPUNK SYSTEM DASHBOARD INSTALLER           ║
    ║                                                           ║
    ╚═══════════════════════════════════════════════════════════╝

EOF

    echo -e "${BOLD}Version:${RESET} $PROJECT_VERSION"
    echo -e "${BOLD}Mode:${RESET} $INSTALL_MODE"
    echo -e "${BOLD}Log:${RESET} $LOG_FILE"
    echo
}

main() {
    # Initialize logging
    create_directory "$LOG_DIR"
    : > "$LOG_FILE"  # Create empty log file

    # Parse arguments
    parse_arguments "$@"

    # Show banner
    print_banner

    # Detect system
    detect_distro

    # Check dependencies
    log_step "Checking dependencies..."
    check_rust
    check_nodejs
    check_npm

    # Install system dependencies
    install_system_dependencies

    # Build project
    if [[ "$OPT_SKIP_BUILD" != "true" ]]; then
        install_frontend_dependencies
        build_rust_backend
    else
        log_warn "Skipping build (--skip-build flag)"
    fi

    # Install
    if [[ "$INSTALL_MODE" == "os" ]]; then
        install_os_mode
    else
        install_app_mode
    fi

    # Post-install
    post_install

    # Success message
    echo
    log_success "${BOLD}Installation complete!${RESET}"
    echo
    if [[ "$INSTALL_MODE" == "app" ]]; then
        echo -e "${CYAN}Run:${RESET} xkor"
        echo -e "${CYAN}Or:${RESET} npm run dev ${DIM}(for development)${RESET}"
    else
        echo -e "${CYAN}Reboot to start xKOR_3RR0R on TTY1${RESET}"
    fi
    echo
    echo -e "${DIM}Logs saved to: $LOG_FILE${RESET}"
    echo
}

# Run main
main "$@"
