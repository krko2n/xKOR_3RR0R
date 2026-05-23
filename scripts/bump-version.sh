#!/usr/bin/env bash
#
# xKOR_3RR0R - Version Bump Utility
# Automatically increments version across all files
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
RESET='\033[0m'

log_info() { echo -e "${CYAN}[INFO]${RESET} $*"; }
log_success() { echo -e "${GREEN}[DONE]${RESET} $*"; }
log_error() { echo -e "${RED}[ERROR]${RESET} $*"; }

# Get current version from package.json
get_current_version() {
    grep '"version"' "$PROJECT_ROOT/package.json" | head -1 | sed 's/.*"\([0-9][^"]*\)".*/\1/'
}

# Parse version into components
parse_version() {
    local version="$1"
    local major minor patch pre

    # Split pre-release suffix if exists
    if [[ "$version" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)-(.+)$ ]]; then
        major="${BASH_REMATCH[1]}"
        minor="${BASH_REMATCH[2]}"
        patch="${BASH_REMATCH[3]}"
        pre="${BASH_REMATCH[4]}"
    elif [[ "$version" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
        major="${BASH_REMATCH[1]}"
        minor="${BASH_REMATCH[2]}"
        patch="${BASH_REMATCH[3]}"
        pre=""
    else
        log_error "Invalid version format: $version"
        exit 1
    fi

    echo "$major $minor $patch $pre"
}

# Bump version
bump_version() {
    local type="$1"
    local current_version="$2"

    read -r major minor patch pre <<< "$(parse_version "$current_version")"

    case "$type" in
        major)
            ((major++))
            minor=0
            patch=0
            ;;
        minor)
            ((minor++))
            patch=0
            ;;
        patch)
            ((patch++))
            ;;
        pre)
            if [[ -z "$pre" ]]; then
                pre="beta.1"
            elif [[ "$pre" =~ ^beta\.([0-9]+)$ ]]; then
                local beta_num="${BASH_REMATCH[1]}"
                ((beta_num++))
                pre="beta.$beta_num"
            else
                log_error "Unsupported pre-release format: $pre"
                exit 1
            fi
            ;;
        release)
            pre=""
            ;;
        *)
            log_error "Unknown bump type: $type"
            exit 1
            ;;
    esac

    if [[ -n "$pre" ]]; then
        echo "$major.$minor.$patch-$pre"
    else
        echo "$major.$minor.$patch"
    fi
}

# Update version in file
update_file() {
    local file="$1"
    local old_version="$2"
    local new_version="$3"

    if [[ ! -f "$file" ]]; then
        log_error "File not found: $file"
        return 1
    fi

    # Escape dots for sed
    local old_escaped="${old_version//./\\.}"
    local new_escaped="$new_version"

    case "$file" in
        */package.json)
            sed -i "s/\"version\": \"$old_escaped\"/\"version\": \"$new_escaped\"/" "$file"
            ;;
        */Cargo.toml)
            sed -i "s/^version = \"$old_escaped\"/version = \"$new_escaped\"/" "$file"
            ;;
        */tauri.conf.json)
            sed -i "s/\"version\": \"$old_escaped\"/\"version\": \"$new_escaped\"/" "$file"
            ;;
        */install.sh|*/upgrade.sh|*/uninstall.sh|*/xkor-doctor.sh)
            sed -i "s/Version: $old_escaped/Version: $new_escaped/" "$file"
            ;;
        *)
            log_error "Unknown file type: $file"
            return 1
            ;;
    esac
}

# Main
main() {
    local bump_type="${1:-patch}"

    cd "$PROJECT_ROOT"

    echo -e "${BOLD}${CYAN}"
    cat <<'EOF'
    ╔═══════════════════════════════════════════════════════════╗
    ║                                                           ║
    ║           xKOR_3RR0R VERSION BUMPER                       ║
    ║                                                           ║
    ╚═══════════════════════════════════════════════════════════╝

EOF
    echo -e "${RESET}"

    # Get current version
    local current_version
    current_version=$(get_current_version)
    log_info "Current version: ${BOLD}$current_version${RESET}"

    # Calculate new version
    local new_version
    new_version=$(bump_version "$bump_type" "$current_version")
    log_info "New version: ${BOLD}${GREEN}$new_version${RESET}"

    echo
    read -p "$(echo -e "${YELLOW}?${RESET} Bump version from $current_version to $new_version? [y/N]: ")" -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Cancelled"
        exit 0
    fi

    # Update all version files
    log_info "Updating version files..."

    update_file "$PROJECT_ROOT/package.json" "$current_version" "$new_version"
    log_success "Updated package.json"

    update_file "$PROJECT_ROOT/src-tauri/Cargo.toml" "$current_version" "$new_version"
    log_success "Updated Cargo.toml"

    update_file "$PROJECT_ROOT/src-tauri/tauri.conf.json" "$current_version" "$new_version"
    log_success "Updated tauri.conf.json"

    update_file "$PROJECT_ROOT/install.sh" "$current_version" "$new_version"
    log_success "Updated install.sh"

    update_file "$PROJECT_ROOT/upgrade.sh" "$current_version" "$new_version"
    log_success "Updated upgrade.sh"

    update_file "$PROJECT_ROOT/uninstall.sh" "$current_version" "$new_version"
    log_success "Updated uninstall.sh"

    update_file "$PROJECT_ROOT/xkor-doctor.sh" "$current_version" "$new_version"
    log_success "Updated xkor-doctor.sh"

    echo
    log_success "${BOLD}Version bumped: $current_version → $new_version${RESET}"
    echo
    echo -e "${CYAN}Next steps:${RESET}"
    echo -e "  1. Review changes: ${BOLD}git diff${RESET}"
    echo -e "  2. Commit: ${BOLD}git commit -am 'chore(release): bump version to $new_version'${RESET}"
    echo -e "  3. Tag: ${BOLD}git tag v$new_version${RESET}"
    echo -e "  4. Push: ${BOLD}git push && git push --tags${RESET}"
    echo
}

# Show help
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    cat <<EOF
xKOR_3RR0R Version Bumper

Usage: $0 [TYPE]

TYPES:
    patch       Bump patch version (2.0.0 → 2.0.1) [default]
    minor       Bump minor version (2.0.0 → 2.1.0)
    major       Bump major version (2.0.0 → 3.0.0)
    pre         Bump pre-release (2.0.0-beta.1 → 2.0.0-beta.2)
    release     Remove pre-release (2.0.0-beta.1 → 2.0.0)

EXAMPLES:
    ./scripts/bump-version.sh patch
    ./scripts/bump-version.sh minor
    ./scripts/bump-version.sh release

EOF
    exit 0
fi

main "$@"
