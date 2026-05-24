#!/usr/bin/env bash
#
# xKOR_3RR0R - Automated Upgrade + Error Reporting + GitHub Integration
# Version: 3.0.0
#
# ONE-COMMAND COMPLETE UPGRADE:
# - Updates project
# - Installs dependencies
# - Verifies runtime
# - Sets up logging
# - Sets up GitHub issue automation
# - Sets up crash handlers
# - Sets up background monitoring
# - Restarts services
#
# Usage: ./upgrade.sh [OPTIONS]
#

set -e
set -o pipefail

# ==============================================================================
# CONFIGURATION
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
VERSION="3.0.0"

# Paths
BACKUP_DIR="$HOME/.local/share/xkor_3rr0r/backups"
BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="$BACKUP_DIR/backup_$BACKUP_TIMESTAMP"

LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/xkor_3rr0r/logs"
LOG_FILE="$LOG_DIR/upgrade_$(date +%Y%m%d_%H%M%S).log"

SCRIPTS_DIR="$PROJECT_ROOT/scripts"
ERROR_REPORTING_DIR="$SCRIPTS_DIR/error-reporting"
MONITORING_SERVICE_DIR="$PROJECT_ROOT/.github/monitoring"

# Options
OPT_FORCE=false
OPT_NO_BACKUP=false
OPT_DEV_MODE=false
OPT_VERBOSE=false
OPT_SKIP_SERVICES=false
OPT_SKIP_GITHUB=false

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
    log_error "Upgrade failed. Check log: $LOG_FILE"
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

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local temp

    while ps -p "$pid" > /dev/null 2>&1; do
        temp=${spinstr#?}
        printf " ${CYAN}%c${RESET} " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b"
    done
    printf "   \b\b\b"
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

create_directory() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir" || log_fatal "Failed to create directory: $dir"
        log_verbose "Created directory: $dir"
    fi
}

detect_distro() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "$ID"
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    elif [[ -f /etc/arch-release ]]; then
        echo "arch"
    elif [[ -f /etc/fedora-release ]]; then
        echo "fedora"
    else
        echo "unknown"
    fi
}

# ==============================================================================
# GIT OPERATIONS
# ==============================================================================

check_git_repo() {
    log_step "Checking Git repository..."

    cd "$PROJECT_ROOT"

    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        log_fatal "Not a Git repository: $PROJECT_ROOT"
    fi

    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    CURRENT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null)
    CURRENT_COMMIT_FULL=$(git rev-parse HEAD 2>/dev/null)

    log_success "Repository OK"
    log_verbose "Branch: $CURRENT_BRANCH"
    log_verbose "Commit: $CURRENT_COMMIT"
}

check_local_changes() {
    log_substep "Checking for local changes..."

    local status
    status=$(git status --porcelain 2>/dev/null)

    if [[ -n "$status" ]]; then
        log_warn "Local changes detected:"
        echo "$status" | head -10 | tee -a "$LOG_FILE"

        if ! ask_yes_no "Discard local changes and continue?" "n"; then
            log_fatal "Upgrade cancelled by user"
        fi

        log_substep "Discarding changes..."
        git checkout -- . || log_fatal "Failed to discard changes"
        git clean -fd || log_warn "Git clean failed"
        log_success "Local changes discarded"
    else
        log_success "No local changes"
    fi
}

get_version_from_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        grep '"version"' "$file" 2>/dev/null | head -1 | sed 's/.*"\([0-9][^"]*\)".*/\1/' || echo "unknown"
    else
        echo "unknown"
    fi
}

fetch_updates() {
    log_step "Fetching updates..."

    cd "$PROJECT_ROOT"

    OLD_VERSION=$(get_version_from_file "$PROJECT_ROOT/package.json")
    log_substep "Current version: ${BOLD}$OLD_VERSION${RESET}"

    log_substep "Connecting to GitHub..."
    git fetch origin "$CURRENT_BRANCH" || log_fatal "Git fetch failed"

    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse "origin/$CURRENT_BRANCH")

    if [[ "$LOCAL" == "$REMOTE" ]]; then
        log_info "Already up to date (commit: ${CURRENT_COMMIT})"
        if ! ask_yes_no "Rebuild and setup error reporting anyway?" "y"; then
            log_info "Nothing to do"
            exit 0
        fi
        SKIP_PULL=true
        NEW_VERSION="$OLD_VERSION"
    else
        NEW_COMMITS=$(git rev-list --count "$LOCAL..$REMOTE")
        NEW_VERSION=$(git show "origin/$CURRENT_BRANCH:package.json" 2>/dev/null | grep '"version"' | head -1 | sed 's/.*"\([0-9][^"]*\)".*/\1/' || echo "$OLD_VERSION")

        echo
        log_raw "${BOLD}${GREEN}╔════════════════════════════════════════════╗${RESET}"
        log_raw "${BOLD}${GREEN}║  UPDATE AVAILABLE                          ║${RESET}"
        log_raw "${BOLD}${GREEN}╠════════════════════════════════════════════╣${RESET}"
        log_raw "${BOLD}${GREEN}║${RESET}  Version: ${CYAN}$OLD_VERSION${RESET} ${DIM}→${RESET} ${BOLD}${GREEN}$NEW_VERSION${RESET}           "
        log_raw "${BOLD}${GREEN}║${RESET}  Commits: ${CYAN}$NEW_COMMITS new${RESET}                      "
        log_raw "${BOLD}${GREEN}╚════════════════════════════════════════════╝${RESET}"
        echo

        SKIP_PULL=false
    fi
}

pull_updates() {
    if [[ "$SKIP_PULL" == "true" ]]; then
        return
    fi

    log_step "Pulling updates..."

    cd "$PROJECT_ROOT"

    log_substep "Changes:"
    git log --oneline "$CURRENT_COMMIT..origin/$CURRENT_BRANCH" | head -5 | tee -a "$LOG_FILE"

    if git pull origin "$CURRENT_BRANCH"; then
        NEW_COMMIT=$(git rev-parse --short HEAD)
        CURRENT_COMMIT_FULL=$(git rev-parse HEAD)
        log_success "Updated: $CURRENT_COMMIT → $NEW_COMMIT"
    else
        log_fatal "Git pull failed"
    fi
}

# ==============================================================================
# BACKUP
# ==============================================================================

create_backup() {
    if [[ "$OPT_NO_BACKUP" == "true" ]]; then
        log_warn "Skipping backup (--no-backup flag)"
        return
    fi

    log_step "Creating backup..."

    create_directory "$BACKUP_DIR"
    create_directory "$BACKUP_PATH"

    local config_dir="$HOME/.config/xkor_3rr0r"
    if [[ -d "$config_dir" ]]; then
        log_substep "Backing up configs..."
        cp -r "$config_dir" "$BACKUP_PATH/config" 2>/dev/null || true
    fi

    local data_dir="$HOME/.local/share/xkor_3rr0r"
    if [[ -d "$data_dir" ]]; then
        log_substep "Backing up data..."
        cp -r "$data_dir" "$BACKUP_PATH/data" 2>/dev/null || true
    fi

    echo "COMMIT=$CURRENT_COMMIT" > "$BACKUP_PATH/version.txt"
    echo "BRANCH=$CURRENT_BRANCH" >> "$BACKUP_PATH/version.txt"
    echo "TIMESTAMP=$BACKUP_TIMESTAMP" >> "$BACKUP_PATH/version.txt"

    log_success "Backup saved: $BACKUP_PATH"

    log_substep "Cleaning old backups (keeping last 5)..."
    local backups=($(ls -t "$BACKUP_DIR" 2>/dev/null))
    local count=0
    for backup in "${backups[@]}"; do
        ((count++))
        if [[ $count -gt 5 ]]; then
            rm -rf "$BACKUP_DIR/$backup"
            log_verbose "Removed old backup: $backup"
        fi
    done
}

# ==============================================================================
# DEPENDENCY INSTALLATION
# ==============================================================================

install_system_dependencies() {
    log_step "Installing system dependencies..."

    local distro=$(detect_distro)
    log_substep "Detected distro: $distro"

    case "$distro" in
        ubuntu|debian)
            log_substep "Installing via apt..."
            if command_exists sudo; then
                sudo apt-get update -qq || log_warn "apt-get update failed"
                sudo apt-get install -y -qq \
                    python3 python3-pip jq curl git gh sqlite3 \
                    >> "$LOG_FILE" 2>&1 || log_warn "Some packages failed to install"
            else
                log_warn "sudo not available, skipping system packages"
            fi
            ;;
        arch)
            log_substep "Installing via pacman..."
            if command_exists sudo; then
                sudo pacman -Sy --noconfirm \
                    python python-pip jq curl git github-cli sqlite \
                    >> "$LOG_FILE" 2>&1 || log_warn "Some packages failed to install"
            else
                log_warn "sudo not available, skipping system packages"
            fi
            ;;
        fedora)
            log_substep "Installing via dnf..."
            if command_exists sudo; then
                sudo dnf install -y \
                    python3 python3-pip jq curl git gh sqlite \
                    >> "$LOG_FILE" 2>&1 || log_warn "Some packages failed to install"
            else
                log_warn "sudo not available, skipping system packages"
            fi
            ;;
        *)
            log_warn "Unknown distro, skipping system package installation"
            log_info "Please manually install: python3, pip, jq, curl, git, gh (GitHub CLI), sqlite3"
            ;;
    esac

    # Python packages
    if command_exists pip3; then
        log_substep "Installing Python packages..."
        pip3 install --user --quiet requests PyGithub 2>&1 | tee -a "$LOG_FILE" || log_warn "Python packages failed"
    else
        log_warn "pip3 not found, skipping Python packages"
    fi

    log_success "Dependencies installed"
}

# ==============================================================================
# BUILD
# ==============================================================================

update_dependencies() {
    log_step "Updating dependencies..."

    cd "$PROJECT_ROOT"

    log_substep "Updating frontend..."
    if [[ -f package-lock.json ]]; then
        npm ci >> "$LOG_FILE" 2>&1 || npm install >> "$LOG_FILE" 2>&1
    else
        npm install >> "$LOG_FILE" 2>&1
    fi

    log_substep "Updating Rust dependencies..."
    cd "$PROJECT_ROOT/src-tauri"
    cargo update >> "$LOG_FILE" 2>&1 || log_warn "Cargo update failed"

    log_success "Dependencies updated"
}

rebuild_project() {
    log_step "Rebuilding project..."

    cd "$PROJECT_ROOT/src-tauri"

    log_substep "Cleaning build cache..."
    cargo clean >> "$LOG_FILE" 2>&1 || log_warn "Cargo clean failed"

    echo -ne "  ${CYAN}⚙${RESET}  Compiling Rust backend (this may take 3-5 minutes)..."

    if [[ "$OPT_DEV_MODE" == "true" ]]; then
        cargo build >> "$LOG_FILE" 2>&1 &
    else
        cargo build --release >> "$LOG_FILE" 2>&1 &
    fi

    local build_pid=$!
    spinner $build_pid
    wait $build_pid

    local build_status=$?
    if [[ $build_status -ne 0 ]]; then
        echo -e " ${RED}✗${RESET}"
        log_fatal "Build failed (see log: $LOG_FILE)"
    else
        echo -e " ${GREEN}✓${RESET}"
    fi

    log_success "Build complete"
}

validate_build() {
    log_step "Validating build..."

    local build_target
    if [[ "$OPT_DEV_MODE" == "true" ]]; then
        build_target="debug"
    else
        build_target="release"
    fi

    local binary="$PROJECT_ROOT/src-tauri/target/$build_target/xkor-3rr0r"

    if [[ ! -f "$binary" ]]; then
        log_fatal "Binary not found: $binary"
    fi

    if [[ ! -x "$binary" ]]; then
        log_fatal "Binary not executable: $binary"
    fi

    log_success "Binary validated: $binary"
}

# ==============================================================================
# ERROR REPORTING SETUP
# ==============================================================================

setup_error_reporting() {
    log_step "Setting up automated error reporting..."

    create_directory "$SCRIPTS_DIR"
    create_directory "$ERROR_REPORTING_DIR"
    create_directory "$MONITORING_SERVICE_DIR"

    # Create error reporting script
    log_substep "Creating error report generator..."
    bash "$PROJECT_ROOT/scripts/create-error-reporting.sh" >> "$LOG_FILE" 2>&1

    # Create GitHub issue manager
    log_substep "Creating GitHub issue manager..."
    bash "$PROJECT_ROOT/scripts/create-github-integration.sh" >> "$LOG_FILE" 2>&1

    # Create monitoring service
    log_substep "Creating monitoring service..."
    bash "$PROJECT_ROOT/scripts/create-monitoring-service.sh" >> "$LOG_FILE" 2>&1

    # Create issue deduplication system
    log_substep "Creating issue deduplication system..."
    bash "$PROJECT_ROOT/scripts/create-deduplication.sh" >> "$LOG_FILE" 2>&1

    log_success "Error reporting configured"
}

setup_github_cli() {
    if [[ "$OPT_SKIP_GITHUB" == "true" ]]; then
        log_warn "Skipping GitHub CLI setup (--skip-github flag)"
        return
    fi

    log_step "Setting up GitHub CLI..."

    if ! command_exists gh; then
        log_warn "GitHub CLI (gh) not found"
        log_info "Please install: https://cli.github.com/"
        log_info "Or run: sudo apt install gh (Ubuntu/Debian)"
        log_warn "Skipping GitHub integration"
        return
    fi

    log_substep "Checking authentication..."
    if gh auth status >> "$LOG_FILE" 2>&1; then
        log_success "GitHub CLI authenticated"
    else
        log_warn "GitHub CLI not authenticated"
        if ask_yes_no "Authenticate GitHub CLI now?" "y"; then
            gh auth login || log_warn "GitHub authentication failed"
        else
            log_warn "Skipping GitHub integration"
        fi
    fi

    # Create issue labels
    log_substep "Creating issue labels..."
    local remote_url=$(git config --get remote.origin.url 2>/dev/null)
    if [[ -n "$remote_url" ]]; then
        local repo=$(echo "$remote_url" | sed 's/.*github.com[:/]\(.*\)\.git/\1/')
        gh label create "bug" --color "d73a4a" --force 2>/dev/null || true
        gh label create "auto-report" --color "0e8a16" --force 2>/dev/null || true
        gh label create "crash" --color "b60205" --force 2>/dev/null || true
        gh label create "ai-debug" --color "1d76db" --force 2>/dev/null || true
        log_success "Labels created"
    else
        log_warn "No GitHub remote found, skipping label creation"
    fi
}

setup_monitoring_service() {
    if [[ "$OPT_SKIP_SERVICES" == "true" ]]; then
        log_warn "Skipping monitoring service setup (--skip-services flag)"
        return
    fi

    log_step "Setting up monitoring service..."

    local service_file="$MONITORING_SERVICE_DIR/xkor-monitor.service"

    if [[ -f "$service_file" ]] && command_exists systemctl; then
        log_substep "Installing systemd service..."

        if command_exists sudo; then
            sudo cp "$service_file" /etc/systemd/system/
            sudo systemctl daemon-reload
            sudo systemctl enable xkor-monitor.service
            sudo systemctl restart xkor-monitor.service

            log_success "Monitoring service enabled"
            log_substep "Status: $(systemctl is-active xkor-monitor.service)"
        else
            log_warn "sudo not available, skipping service installation"
        fi
    else
        log_warn "Monitoring service file not found or systemd not available"
        log_info "Background monitoring will run manually when needed"
    fi
}

# ==============================================================================
# MAIN
# ==============================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force)
                OPT_FORCE=true
                ;;
            --no-backup)
                OPT_NO_BACKUP=true
                ;;
            --dev)
                OPT_DEV_MODE=true
                ;;
            --skip-services)
                OPT_SKIP_SERVICES=true
                ;;
            --skip-github)
                OPT_SKIP_GITHUB=true
                ;;
            -v|--verbose)
                OPT_VERBOSE=true
                ;;
            -h|--help)
                cat <<EOF
xKOR_3RR0R Automated Upgrade + Error Reporting

Usage: $0 [OPTIONS]

OPTIONS:
    --force             Skip confirmation prompts
    --no-backup         Skip creating backup
    --dev               Development mode (debug build)
    --skip-services     Skip systemd service installation
    --skip-github       Skip GitHub CLI setup
    -v, --verbose       Verbose output
    -h, --help          Show this help

EXAMPLES:
    ./upgrade.sh
    ./upgrade.sh --force
    ./upgrade.sh --skip-services --verbose

FEATURES:
    ✓ Automated upgrade
    ✓ Dependency installation
    ✓ Error logging
    ✓ GitHub issue automation
    ✓ Crash reporting
    ✓ Background monitoring
    ✓ Issue deduplication

ROLLBACK:
    Backups: $BACKUP_DIR
    Manual rollback: git reset --hard <commit>

EOF
                exit 0
                ;;
            *)
                log_fatal "Unknown option: $1 (use --help for usage)"
                ;;
        esac
        shift
    done
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
    ║              AUTOMATED SYSTEM UPGRADE v3.0               ║
    ║                                                           ║
    ╚═══════════════════════════════════════════════════════════╝

EOF
}

main() {
    # Initialize logging
    create_directory "$LOG_DIR"
    : > "$LOG_FILE"

    parse_arguments "$@"

    print_banner

    # Pre-flight checks
    check_git_repo
    check_local_changes

    # Fetch updates
    fetch_updates

    # Create backup
    create_backup

    # Install dependencies
    install_system_dependencies

    # Pull updates
    pull_updates

    # Update project dependencies
    update_dependencies

    # Rebuild
    rebuild_project

    # Validate
    validate_build

    # Setup error reporting
    setup_error_reporting

    # Setup GitHub integration
    setup_github_cli

    # Setup monitoring service
    setup_monitoring_service

    # Success banner
    echo
    log_raw "${BOLD}${GREEN}╔════════════════════════════════════════════════════════╗${RESET}"
    log_raw "${BOLD}${GREEN}║                                                        ║${RESET}"
    log_raw "${BOLD}${GREEN}║            ✓ UPGRADE SUCCESSFUL                        ║${RESET}"
    log_raw "${BOLD}${GREEN}║                                                        ║${RESET}"
    log_raw "${BOLD}${GREEN}╠════════════════════════════════════════════════════════╣${RESET}"
    log_raw "${BOLD}${GREEN}║${RESET}  Version:     ${CYAN}$OLD_VERSION${RESET} ${DIM}→${RESET} ${BOLD}${GREEN}$NEW_VERSION${RESET}"
    log_raw "${BOLD}${GREEN}║${RESET}  Backup:      ${DIM}$BACKUP_PATH${RESET}"
    log_raw "${BOLD}${GREEN}║${RESET}  Log:         ${DIM}$LOG_FILE${RESET}"
    log_raw "${BOLD}${GREEN}║${RESET}  Monitoring:  ${GREEN}Active${RESET}"
    log_raw "${BOLD}${GREEN}║${RESET}  Error Report: ${GREEN}Automated${RESET}"
    log_raw "${BOLD}${GREEN}║                                                        ║${RESET}"
    log_raw "${BOLD}${GREEN}╚════════════════════════════════════════════════════════╝${RESET}"
    echo
    log_info "${CYAN}${BOLD}Next steps:${RESET}"
    log_info "  • Launch: ${BOLD}xkor${RESET}"
    log_info "  • View logs: ${BOLD}journalctl -u xkor-login -f${RESET}"
    log_info "  • Test crash reporting: ${BOLD}./scripts/test-error-reporting.sh${RESET}"
    echo
}

# Trap errors
trap 'handle_error' ERR

handle_error() {
    log_error "Upgrade failed!"
    log_error "Check log: $LOG_FILE"

    if [[ "$OPT_NO_BACKUP" != "true" ]] && [[ -d "$BACKUP_PATH" ]]; then
        log_info "Backup available at: $BACKUP_PATH"
    fi

    exit 1
}

# Run main
main "$@"
