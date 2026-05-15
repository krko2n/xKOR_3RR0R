# @summary: File manifest for integrity checks.
#!/bin/bash
# xKOR_3RR0R - Manifest library
# Tracks everything the installer creates.
# Manifest lives at /var/lib/xkor_3rr0r/manifest (survives repo deletion)
# Format: KEY=VALUE, one per line

manifest_init() {
    local version="${1:-unknown}" repo="${2:-unknown}"
    mkdir -p "$XKOR_MANIFEST_DIR"
    cat > "$XKOR_MANIFEST_FILE" << MEOF
VERSION=$version
INSTALLER_VERSION=9
INSTALL_DATE=$(date -Iseconds)
INSTALL_PATH=$XKOR_INSTALL_DIR
REPO_PATH=$repo
MEOF
    chmod 644 "$XKOR_MANIFEST_FILE"
}

manifest_record() {
    local type="$1" value="$2"
    [[ -z "$type" || -z "$value" ]] && return
    grep -qxF "${type}=${value}" "$XKOR_MANIFEST_FILE" 2>/dev/null || \
        echo "${type}=${value}" >> "$XKOR_MANIFEST_FILE"
}

manifest_exists() { [[ -f "$XKOR_MANIFEST_FILE" ]]; }

manifest_get() {
    [[ -f "$XKOR_MANIFEST_FILE" ]] || return
    grep "^${1}=" "$XKOR_MANIFEST_FILE" | cut -d= -f2-
}

manifest_get_one() { manifest_get "$1" | head -1; }

manifest_print() {
    manifest_exists || { echo "No manifest at $XKOR_MANIFEST_FILE"; return; }
    cat "$XKOR_MANIFEST_FILE"
}