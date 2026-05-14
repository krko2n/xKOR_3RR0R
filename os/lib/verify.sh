#!/bin/bash
# xKOR_3RR0R - Verification library

VERIFY_ERRORS=0; VERIFY_WARNINGS=0

_vlog()      { _log -e "$@"; }
vok()        { _vlog "${GREEN}[  OK  ]${RESET}   $1"; }
vwarn()      { _vlog "${YELLOW}[ WARN ]${RESET}   $1"; ((VERIFY_WARNINGS++)); }
vfail_soft() { _vlog "${RED}[ FAIL ]${RESET}   $1"; ((VERIFY_ERRORS++)); }

verify_check() {
    local desc="$1" result="$2"
    case "$result" in
        ok)   vok "$desc" ;;
        warn) vwarn "$desc" ;;
        *)    vfail_soft "$desc" ;;
    esac
}

verify_binary() { command -v "$1" > /dev/null 2>&1 && echo "ok" || echo "fail"; }
verify_file()   { [[ -f "$1" ]] && echo "ok" || echo "fail"; }
verify_dir()    { [[ -d "$1" ]] && echo "ok" || echo "fail"; }
verify_service(){ systemctl is-enabled "$1" > /dev/null 2>&1 && echo "ok" || echo "fail"; }
verify_syntax() { node --check "$1" > /dev/null 2>&1 && echo "ok" || echo "fail"; }

verify_pam() {
    local f="$XKOR_INSTALL_DIR/os/login/pam.js"
    [[ -f "$f" ]] || { echo "fail"; return; }
    grep -q "authenticate-pam" "$f" && { echo "fail"; return; }
    grep -q "pamtester" "$f" && echo "ok" || echo "fail"
}

run_verify() {
    VERIFY_ERRORS=0; VERIFY_WARNINGS=0
    echo
    step "=== Verifying installation ==="

    echo; info "System binaries:"
    verify_check "node $(node --version 2>/dev/null)" "$(verify_binary node)"
    verify_check "npm" "$(verify_binary npm)"
    verify_check "pamtester" "$(verify_binary pamtester)"
    verify_check "startx" "$(verify_binary startx)"
    verify_check "unclutter" "$(verify_binary unclutter)"

    echo; info "Files:"
    verify_check "Install dir" "$(verify_dir "$XKOR_INSTALL_DIR")"
    verify_check "src/main.js" "$(verify_file "$XKOR_INSTALL_DIR/src/main.js")"
    verify_check "os/login/login.js" "$(verify_file "$XKOR_INSTALL_DIR/os/login/login.js")"
    verify_check "os/login/pam.js" "$(verify_file "$XKOR_INSTALL_DIR/os/login/pam.js")"
    verify_check "os/login/start-login.sh" "$(verify_file "$XKOR_INSTALL_DIR/os/login/start-login.sh")"
    verify_check "os/xorg/xkor-session.sh" "$(verify_file "$XKOR_INSTALL_DIR/os/xorg/xkor-session.sh")"
    verify_check "node_modules" "$(verify_dir "$XKOR_INSTALL_DIR/node_modules")"
    verify_check "node-pty rebuilt" "$(verify_file "$XKOR_INSTALL_DIR/node_modules/.node-pty-rebuilt")"

    echo; info "Config:"
    verify_check "pam.js uses pamtester" "$(verify_pam)"
    verify_check "login.js syntax" "$(verify_syntax "$XKOR_INSTALL_DIR/os/login/login.js")"

    echo; info "Services:"
    verify_check "xkor-login.service enabled" "$(verify_service xkor-login.service)"

    echo; info "Manifest:"
    if manifest_exists; then
        vok "Found: $XKOR_MANIFEST_FILE"
        vok "Version:  $(manifest_get_one VERSION)"
        vok "Date:     $(manifest_get_one INSTALL_DATE)"
    else
        vwarn "No manifest found"
    fi

    echo
    if [[ $VERIFY_ERRORS -eq 0 && $VERIFY_WARNINGS -eq 0 ]]; then
        ok "=== All checks passed ==="
    elif [[ $VERIFY_ERRORS -eq 0 ]]; then
        warn "=== Passed with $VERIFY_WARNINGS warning(s) ==="
    else
        _log -e "${RED}[ FAIL ]${RESET} === $VERIFY_ERRORS error(s), $VERIFY_WARNINGS warning(s) ==="
        return 1
    fi
    echo
}