#!/bin/bash
# Skills CLI Installation Script
# Generated: 2026-05-24
# Purpose: Install Agent Skills globally with automatic retries and error handling

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] ✓${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ✗${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] ⚠${NC} $1"
}

# Create logs directory
LOGS_DIR="./logs"
mkdir -p "$LOGS_DIR"
INSTALL_LOG="$LOGS_DIR/install_$(date +%Y%m%d_%H%M%S).log"

log_info "Starting Skills CLI Installation" | tee -a "$INSTALL_LOG"
log_info "Log file: $INSTALL_LOG" | tee -a "$INSTALL_LOG"
echo "" | tee -a "$INSTALL_LOG"

# Check Node.js
log_info "Checking Node.js installation..." | tee -a "$INSTALL_LOG"
if ! command -v node &> /dev/null; then
    log_error "Node.js is not installed. Please install Node.js first." | tee -a "$INSTALL_LOG"
    exit 1
fi
NODE_VERSION=$(node --version)
log_success "Node.js: $NODE_VERSION" | tee -a "$INSTALL_LOG"

# Check npm
if ! command -v npm &> /dev/null; then
    log_error "npm is not installed. Please install npm first." | tee -a "$INSTALL_LOG"
    exit 1
fi
NPM_VERSION=$(npm --version)
log_success "npm: $NPM_VERSION" | tee -a "$INSTALL_LOG"

# Check npx
if ! command -v npx &> /dev/null; then
    log_error "npx is not installed. Please install npx first." | tee -a "$INSTALL_LOG"
    exit 1
fi
log_success "npx is available" | tee -a "$INSTALL_LOG"
echo "" | tee -a "$INSTALL_LOG"

# Function to install a skill with retries
install_skill() {
    local repo=$1
    local skill=$2
    local max_retries=3
    local retry=0

    log_info "Installing skill: $skill from $repo" | tee -a "$INSTALL_LOG"

    while [ $retry -lt $max_retries ]; do
        if npx skills@latest add "$repo" --skill "$skill" --global --yes 2>&1 | tee -a "$INSTALL_LOG"; then
            log_success "Successfully installed: $skill" | tee -a "$INSTALL_LOG"
            return 0
        else
            retry=$((retry + 1))
            if [ $retry -lt $max_retries ]; then
                log_warn "Failed to install $skill. Retrying ($retry/$max_retries)..." | tee -a "$INSTALL_LOG"
                sleep 2
            fi
        fi
    done

    log_error "Failed to install $skill after $max_retries attempts" | tee -a "$INSTALL_LOG"
    return 1
}

# Install skills
echo "=== INSTALLING SKILLS ===" | tee -a "$INSTALL_LOG"
echo "" | tee -a "$INSTALL_LOG"

# Counters
TOTAL=4
SUCCESS=0
FAILED=0

# 1. find-skills
if install_skill "vercel-labs/skills" "find-skills"; then
    SUCCESS=$((SUCCESS + 1))
else
    FAILED=$((FAILED + 1))
fi
echo "" | tee -a "$INSTALL_LOG"

# 2. mcp-builder
if install_skill "anthropics/skills" "mcp-builder"; then
    SUCCESS=$((SUCCESS + 1))
else
    FAILED=$((FAILED + 1))
fi
echo "" | tee -a "$INSTALL_LOG"

# 3. frontend-design
if install_skill "anthropics/skills" "frontend-design"; then
    SUCCESS=$((SUCCESS + 1))
else
    FAILED=$((FAILED + 1))
fi
echo "" | tee -a "$INSTALL_LOG"

# 4. web-design-guidelines
if install_skill "vercel-labs/agent-skills" "web-design-guidelines"; then
    SUCCESS=$((SUCCESS + 1))
else
    FAILED=$((FAILED + 1))
fi
echo "" | tee -a "$INSTALL_LOG"

# Summary
echo "=== INSTALLATION SUMMARY ===" | tee -a "$INSTALL_LOG"
log_success "Successfully installed: $SUCCESS/$TOTAL skills" | tee -a "$INSTALL_LOG"
if [ $FAILED -gt 0 ]; then
    log_error "Failed installations: $FAILED/$TOTAL skills" | tee -a "$INSTALL_LOG"
fi
echo "" | tee -a "$INSTALL_LOG"

log_info "Listing all installed skills..." | tee -a "$INSTALL_LOG"
npx skills@latest list --global 2>&1 | tee -a "$INSTALL_LOG"

echo "" | tee -a "$INSTALL_LOG"
log_info "Installation complete! Check $INSTALL_LOG for details." | tee -a "$INSTALL_LOG"

# Exit with appropriate code
if [ $FAILED -gt 0 ]; then
    exit 1
fi
exit 0
