#!/bin/bash
# Skills CLI Verification Script
# Generated: 2026-05-24
# Purpose: Verify all installed Agent Skills

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
VERIFY_LOG="$LOGS_DIR/verify_$(date +%Y%m%d_%H%M%S).log"

log_info "Starting Skills Verification" | tee "$VERIFY_LOG"
log_info "Log file: $VERIFY_LOG" | tee -a "$VERIFY_LOG"
echo "" | tee -a "$VERIFY_LOG"

# Expected skills
EXPECTED_SKILLS=("find-skills" "mcp-builder" "frontend-design" "web-design-guidelines")
FOUND=0
MISSING=0

log_info "Checking for expected skills..." | tee -a "$VERIFY_LOG"
echo "" | tee -a "$VERIFY_LOG"

for skill in "${EXPECTED_SKILLS[@]}"; do
    # Check if skill directory exists
    SKILL_DIR="$HOME/.agents/skills/$skill"
    if [ -d "$SKILL_DIR" ]; then
        log_success "Found: $skill" | tee -a "$VERIFY_LOG"
        FOUND=$((FOUND + 1))

        log_success "  Directory exists: $SKILL_DIR" | tee -a "$VERIFY_LOG"

        # Check for SKILL.md
        if [ -f "$SKILL_DIR/SKILL.md" ]; then
            log_success "  SKILL.md exists" | tee -a "$VERIFY_LOG"
        else
            log_warn "  SKILL.md not found" | tee -a "$VERIFY_LOG"
        fi
    else
        log_error "Missing: $skill" | tee -a "$VERIFY_LOG"
        log_error "  Directory not found: $SKILL_DIR" | tee -a "$VERIFY_LOG"
        MISSING=$((MISSING + 1))
    fi
    echo "" | tee -a "$VERIFY_LOG"
done

# Summary
echo "=== VERIFICATION SUMMARY ===" | tee -a "$VERIFY_LOG"
log_info "Total expected: ${#EXPECTED_SKILLS[@]}" | tee -a "$VERIFY_LOG"
log_success "Found: $FOUND" | tee -a "$VERIFY_LOG"
if [ $MISSING -gt 0 ]; then
    log_error "Missing: $MISSING" | tee -a "$VERIFY_LOG"
fi
echo "" | tee -a "$VERIFY_LOG"

# List all installed skills
log_info "All installed global skills:" | tee -a "$VERIFY_LOG"
npx skills@latest list --global 2>&1 | tee -a "$VERIFY_LOG"

echo "" | tee -a "$VERIFY_LOG"
log_info "Verification complete! Check $VERIFY_LOG for details." | tee -a "$VERIFY_LOG"

# Exit with appropriate code
if [ $MISSING -gt 0 ]; then
    exit 1
fi
exit 0
