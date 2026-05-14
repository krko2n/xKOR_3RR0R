#!/bin/bash
# xKOR_3RR0R - Cleanup library
# Works even if: repo deleted, install interrupted, manifest missing

cleanup_services() {
    step "Stopping and disabling services..."
    for svc in xkor-login xkor-ui; do
        systemctl is-active --quiet "${svc}.service" 2>/dev/null && \
            systemctl stop "${svc}.service" 2>/dev/null || true
        systemctl is-enabled --quiet "${svc}.service" 2>/dev/null && \
            systemctl disable "${svc}.service" 2>/dev/null || true
    done
    safe_delete "$XKOR_SERVICE_LOGIN"
    safe_delete "$XKOR_SERVICE_UI"
    systemctl daemon-reload 2>/dev/null || true
    ok "Services cleaned"
}

cleanup_from_manifest() {
    manifest_exists || return 1
    step "Manifest-driven cleanup..."

    while IFS= read -r path; do safe_delete "$path"; done < <(manifest_get "SYMLINK")
    while IFS= read -r path; do
        [[ "$path" == "$XKOR_MANIFEST_FILE" ]] && continue
        safe_delete "$path"
    done < <(manifest_get "FILE")
    while IFS= read -r svc; do
        systemctl stop "$svc" 2>/dev/null || true
        systemctl disable "$svc" 2>/dev/null || true
    done < <(manifest_get "SERVICE")
    safe_delete "$XKOR_SERVICE_LOGIN"
    safe_delete "$XKOR_SERVICE_UI"
    systemctl daemon-reload 2>/dev/null || true
    while IFS= read -r theme; do
        safe_delete_dir "/usr/share/plymouth/themes/$theme"
    done < <(manifest_get "PLYMOUTH")
    while IFS= read -r path; do
        path_is_safe "$path" && rmdir "$path" 2>/dev/null || true
    done < <(manifest_get "DIR" | sort -r)
    ok "Manifest cleanup done"
    return 0
}

cleanup_fallback() {
    step "Fallback cleanup (no manifest)..."
    cleanup_services
    for dir in "/opt/xkor_3rr0r" "/opt/xKOR_3RR0R" "/opt/xkor-3rr0r"; do
        path_is_safe "$dir" && safe_delete_dir "$dir"
    done
    safe_delete_dir "$XKOR_PLYMOUTH_DIR"
    safe_delete "$XKOR_BIN"
    safe_delete "/usr/bin/xkor"
    systemctl daemon-reload 2>/dev/null || true
    ok "Fallback cleanup done"
}

run_cleanup() {
    local remove_logs="${1:-0}"
    echo
    step "=== Starting cleanup ==="
    cleanup_from_manifest || cleanup_fallback
    safe_delete "$XKOR_BIN"
    safe_delete_dir "$XKOR_PLYMOUTH_DIR"
    [[ "$remove_logs" == "1" ]] && safe_delete_dir "$XKOR_LOG_DIR" \
        || info "Logs kept at $XKOR_LOG_DIR"
    safe_delete "$XKOR_MANIFEST_FILE"
    rmdir "$XKOR_MANIFEST_DIR" 2>/dev/null || true
    ok "=== Cleanup complete ==="
    echo
}