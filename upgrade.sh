#!/usr/bin/env bash
#
# xKOR_3RR0R - Professional Upgrade Script
# Version: 2.1.0-beta.1
#
# One-command upgrade with rollback support
# Usage: ./upgrade.sh [--force] [--no-backup] [--dev]
#

set -e
set -o pipefail

# ==============================================================================
# CONFIGURATION
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

# Backup
BACKUP_DIR="$HOME/.local/share/xkor_3rr0r/backups"
BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="$BACKUP_DIR/backup_$BACKUP_TIMESTAMP"

# Options
OPT_FORCE=false
OPT_NO_BACKUP=false
OPT_DEV_MODE=false
OPT_VERBOSE=false

# Logging
LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/xkor_3rr0r/logs"
LOG_FILE="$LOG_DIR/upgrade_$(date +%Y%m%d_%H%M%S).log"

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

# Progress spinner
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

    # Get current version
    OLD_VERSION=$(get_version_from_file "$PROJECT_ROOT/package.json")
    log_substep "Current version: ${BOLD}$OLD_VERSION${RESET}"

    # Fetch from remote
    log_substep "Connecting to GitHub..."
    git fetch origin "$CURRENT_BRANCH" || log_fatal "Git fetch failed"

    # Check if updates available
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse "origin/$CURRENT_BRANCH")

    if [[ "$LOCAL" == "$REMOTE" ]]; then
        log_info "Already up to date (commit: ${CURRENT_COMMIT})"
        if ! ask_yes_no "Rebuild anyway?" "n"; then
            log_info "Nothing to do"
            exit 0
        fi
        SKIP_PULL=true
        NEW_VERSION="$OLD_VERSION"
    else
        NEW_COMMITS=$(git rev-list --count "$LOCAL..$REMOTE")

        # Preview new version from remote
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

    # Show what will be pulled
    log_substep "Changes:"
    git log --oneline "$CURRENT_COMMIT..origin/$CURRENT_BRANCH" | head -5 | tee -a "$LOG_FILE"

    # Pull
    if git pull origin "$CURRENT_BRANCH"; then
        NEW_COMMIT=$(git rev-parse --short HEAD)
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

    # Backup configs
    local config_dir="$HOME/.config/xkor_3rr0r"
    if [[ -d "$config_dir" ]]; then
        log_substep "Backing up configs..."
        cp -r "$config_dir" "$BACKUP_PATH/config" 2>/dev/null || true
    fi

    # Backup data
    local data_dir="$HOME/.local/share/xkor_3rr0r"
    if [[ -d "$data_dir" ]]; then
        log_substep "Backing up data..."
        cp -r "$data_dir" "$BACKUP_PATH/data" 2>/dev/null || true
    fi

    # Save version info
    echo "COMMIT=$CURRENT_COMMIT" > "$BACKUP_PATH/version.txt"
    echo "BRANCH=$CURRENT_BRANCH" >> "$BACKUP_PATH/version.txt"
    echo "TIMESTAMP=$BACKUP_TIMESTAMP" >> "$BACKUP_PATH/version.txt"

    log_success "Backup saved: $BACKUP_PATH"

    # Clean old backups (keep last 5)
    log_substep "Cleaning old backups..."
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

restore_backup() {
    if [[ ! -d "$BACKUP_PATH" ]]; then
        log_error "No backup found at: $BACKUP_PATH"
        return 1
    fi

    log_step "Restoring from backup..."

    # Restore configs
    if [[ -d "$BACKUP_PATH/config" ]]; then
        log_substep "Restoring configs..."
        cp -r "$BACKUP_PATH/config" "$HOME/.config/xkor_3rr0r" 2>/dev/null || true
    fi

    # Restore data
    if [[ -d "$BACKUP_PATH/data" ]]; then
        log_substep "Restoring data..."
        cp -r "$BACKUP_PATH/data" "$HOME/.local/share/xkor_3rr0r" 2>/dev/null || true
    fi

    # Restore Git state
    if [[ -f "$BACKUP_PATH/version.txt" ]]; then
        source "$BACKUP_PATH/version.txt"
        if [[ -n "$COMMIT" ]]; then
            log_substep "Restoring Git commit: $COMMIT..."
            cd "$PROJECT_ROOT"
            git reset --hard "$COMMIT" || log_warn "Git reset failed"
        fi
    fi

    log_success "Backup restored"
}

# ==============================================================================
# BUILD
# ==============================================================================

update_dependencies() {
    log_step "Updating dependencies..."

    cd "$PROJECT_ROOT"

    # Frontend dependencies
    log_substep "Updating frontend..."
    if [[ -f package-lock.json ]]; then
        npm ci || npm install
    elif [[ -f pnpm-lock.yaml ]]; then
        command_exists pnpm && pnpm install
    elif [[ -f bun.lockb ]]; then
        command_exists bun && bun install
    else
        npm install
    fi

    # Cargo dependencies
    log_substep "Updating Rust dependencies..."
    cd "$PROJECT_ROOT/src-tauri"
    cargo update || log_warn "Cargo update failed"

    log_success "Dependencies updated"
}

rebuild_project() {
    log_step "Rebuilding project..."

    cd "$PROJECT_ROOT/src-tauri"

    # Clean build artifacts
    log_substep "Cleaning build cache..."
    cargo clean 2>&1 | tee -a "$LOG_FILE" > /dev/null || log_warn "Cargo clean failed"

    # Rebuild with progress indicator
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

# ==============================================================================
# VALIDATION
# ==============================================================================

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
            -v|--verbose)
                OPT_VERBOSE=true
                ;;
            -h|--help)
                cat <<EOF
xKOR_3RR0R Upgrade Script

Usage: $0 [OPTIONS]

OPTIONS:
    --force         Skip confirmation prompts
    --no-backup     Skip creating backup
    --dev           Development mode (debug build)
    -v, --verbose   Verbose output
    -h, --help      Show this help

EXAMPLES:
    ./upgrade.sh
    ./upgrade.sh --force
    ./upgrade.sh --no-backup --verbose

ROLLBACK:
    Backups are stored in: $BACKUP_DIR
    To manually rollback: git reset --hard <commit>

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
    ║                   SYSTEM UPGRADE                          ║
    ║                                                           ║
    ╚═══════════════════════════════════════════════════════════╝

EOF
}

main() {
    # Initialize logging
    create_directory "$LOG_DIR"
    : > "$LOG_FILE"

    # Parse arguments
    parse_arguments "$@"

    # Show banner
    print_banner

    # Pre-flight checks
    check_git_repo
    check_local_changes

    # Fetch updates
    fetch_updates

    # Create backup
    create_backup

    # Pull updates
    pull_updates

    # Update dependencies
    update_dependencies

    # Rebuild
    rebuild_project

    # Validate
    validate_build

    # Success banner
    echo
    log_raw "${BOLD}${GREEN}╔════════════════════════════════════════════════════════╗${RESET}"
    log_raw "${BOLD}${GREEN}║                                                        ║${RESET}"
    log_raw "${BOLD}${GREEN}║            ✓ UPGRADE SUCCESSFUL                        ║${RESET}"
    log_raw "${BOLD}${GREEN}║                                                        ║${RESET}"
    log_raw "${BOLD}${GREEN}╠════════════════════════════════════════════════════════╣${RESET}"
    log_raw "${BOLD}${GREEN}║${RESET}  Version:  ${CYAN}$OLD_VERSION${RESET} ${DIM}→${RESET} ${BOLD}${GREEN}$NEW_VERSION${RESET}"
    log_raw "${BOLD}${GREEN}║${RESET}  Backup:   ${DIM}$BACKUP_PATH${RESET}"
    log_raw "${BOLD}${GREEN}║${RESET}  Log:      ${DIM}$LOG_FILE${RESET}"
    log_raw "${BOLD}${GREEN}║                                                        ║${RESET}"
    log_raw "${BOLD}${GREEN}╚════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo -e "${CYAN}${BOLD}Launch xKOR:${RESET} ${BOLD}xkor${RESET}"
    echo -e "${DIM}Or reboot to start in OS Mode${RESET}"
    echo
}

# Trap errors and offer rollback
trap 'handle_error' ERR

handle_error() {
    log_error "Upgrade failed!"

    if [[ "$OPT_NO_BACKUP" != "true" ]] && [[ -d "$BACKUP_PATH" ]]; then
        if ask_yes_no "Restore from backup?" "y"; then
            restore_backup
        fi
    fi

    exit 1
}

# Run main
main "$@"
