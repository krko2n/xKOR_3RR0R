#!/usr/bin/env bash
#
# xKOR_3RR0R - Error Reporting System Test Suite
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ERROR_REPORTING="$SCRIPT_DIR/error-reporting"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${RESET} $*"
}

log_success() {
    echo -e "${GREEN}[PASS]${RESET} $*"
}

log_error() {
    echo -e "${RED}[FAIL]${RESET} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${RESET} $*"
}

print_banner() {
    cat <<'EOF'
╔════════════════════════════════════════════════════════╗
║                                                        ║
║        xKOR_3RR0R ERROR REPORTING TEST SUITE          ║
║                                                        ║
╚════════════════════════════════════════════════════════╝

EOF
}

test_data_collection() {
    log_info "Test 1: Data collection..."

    if bash "$ERROR_REPORTING/collect-error-data.sh" \
        "test_crash" \
        "This is a test crash" \
        "Stack trace line 1\nStack trace line 2" > /tmp/test_error.json; then

        if [[ -s /tmp/test_error.json ]]; then
            log_success "Data collection works"
            return 0
        else
            log_error "Empty output file"
            return 1
        fi
    else
        log_error "Data collection failed"
        return 1
    fi
}

test_report_generation() {
    log_info "Test 2: Report generation..."

    if python3 "$ERROR_REPORTING/generate-error-report.py" /tmp/test_error.json > /tmp/test_report.json; then
        if [[ -s /tmp/test_report.json ]]; then
            local signature=$(jq -r .signature /tmp/test_report.json 2>/dev/null)
            if [[ -n "$signature" ]]; then
                log_success "Report generation works (signature: $signature)"
                return 0
            else
                log_error "Invalid report format"
                return 1
            fi
        else
            log_error "Empty report"
            return 1
        fi
    else
        log_error "Report generation failed"
        return 1
    fi
}

test_deduplication() {
    log_info "Test 3: Deduplication system..."

    # Initialize database
    bash "$ERROR_REPORTING/dedup-manager.sh" init

    # Record test issue
    bash "$ERROR_REPORTING/dedup-manager.sh" record "test_signature_123" "test_crash" "999"

    # Query it back
    local result=$(bash "$ERROR_REPORTING/dedup-manager.sh" query "test_signature_123")

    if [[ -n "$result" ]]; then
        log_success "Deduplication works"
        return 0
    else
        log_error "Deduplication failed"
        return 1
    fi
}

test_github_cli() {
    log_info "Test 4: GitHub CLI availability..."

    if command -v gh >/dev/null 2>&1; then
        if gh auth status >/dev/null 2>&1; then
            log_success "GitHub CLI authenticated"
            return 0
        else
            log_warn "GitHub CLI found but not authenticated"
            log_info "Run: gh auth login"
            return 0
        fi
    else
        log_warn "GitHub CLI not found"
        log_info "Install: sudo apt install gh (Ubuntu/Debian)"
        return 0
    fi
}

test_full_pipeline() {
    log_info "Test 5: Full error reporting pipeline..."

    log_info "Simulating crash..."

    # Create fake crash report
    local crash_file="$PROJECT_ROOT/diagnostics/crashes/test_$(date +%s).log"
    mkdir -p "$PROJECT_ROOT/diagnostics/crashes"

    cat > "$crash_file" <<EOF
================================================================================
  xKOR_3RR0R CRASH REPORT
================================================================================

Timestamp: $(date)
Crash Type: test_crash
Message: Automated test crash

System Information:
$(uname -a)

Stack Trace:
test_function_1() at test.rs:42
test_function_2() at test.rs:84
main() at test.rs:100

================================================================================
EOF

    log_info "Running error reporter..."

    if bash "$ERROR_REPORTING/report-error.sh" \
        "test_crash" \
        "Automated test crash - please ignore" \
        "test_function_1() at test.rs:42" 2>&1 | tee /tmp/test_output.log; then

        log_success "Error reporting pipeline executed"

        # Check if report was created
        if ls "$PROJECT_ROOT/crash_reports"/*test*.md >/dev/null 2>&1; then
            log_success "Crash report created"
        else
            log_warn "Crash report file not found"
        fi

        return 0
    else
        log_error "Error reporting pipeline failed"
        return 1
    fi
}

cleanup() {
    log_info "Cleaning up test files..."

    rm -f /tmp/test_error.json
    rm -f /tmp/test_report.json
    rm -f /tmp/test_output.log

    # Remove test crash report
    rm -f "$PROJECT_ROOT/diagnostics/crashes"/test_*.log

    log_success "Cleanup complete"
}

run_all_tests() {
    local passed=0
    local failed=0

    print_banner

    test_data_collection && ((passed++)) || ((failed++))
    echo

    test_report_generation && ((passed++)) || ((failed++))
    echo

    test_deduplication && ((passed++)) || ((failed++))
    echo

    test_github_cli && ((passed++)) || ((failed++))
    echo

    test_full_pipeline && ((passed++)) || ((failed++))
    echo

    cleanup
    echo

    # Summary
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║                   TEST RESULTS                         ║"
    echo "╠════════════════════════════════════════════════════════╣"
    printf "║  Passed:  %-44s ║\n" "${GREEN}$passed${RESET}"
    printf "║  Failed:  %-44s ║\n" "${RED}$failed${RESET}"
    echo "╚════════════════════════════════════════════════════════╝"
    echo

    if [[ $failed -eq 0 ]]; then
        log_success "All tests passed!"
        exit 0
    else
        log_error "$failed tests failed"
        exit 1
    fi
}

main() {
    if [[ $# -eq 0 ]]; then
        run_all_tests
    else
        case "$1" in
            data)
                test_data_collection
                ;;
            report)
                test_report_generation
                ;;
            dedup)
                test_deduplication
                ;;
            github)
                test_github_cli
                ;;
            pipeline)
                test_full_pipeline
                ;;
            all)
                run_all_tests
                ;;
            *)
                echo "Usage: $0 [test_name]"
                echo ""
                echo "Tests:"
                echo "  data      - Test data collection"
                echo "  report    - Test report generation"
                echo "  dedup     - Test deduplication"
                echo "  github    - Test GitHub CLI"
                echo "  pipeline  - Test full pipeline"
                echo "  all       - Run all tests (default)"
                exit 1
                ;;
        esac
    fi
}

main "$@"
