#!/usr/bin/env bash
#
# Creates issue deduplication system
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ERROR_REPORTING_DIR="$SCRIPT_DIR/error-reporting"

mkdir -p "$ERROR_REPORTING_DIR"

# ==============================================================================
# DEDUPLICATION DATABASE SCHEMA
# ==============================================================================

cat > "$ERROR_REPORTING_DIR/init-dedup-db.sql" << 'SQLEOF'
-- xKOR_3RR0R Issue Deduplication Database

CREATE TABLE IF NOT EXISTS issues (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    signature TEXT UNIQUE NOT NULL,
    github_issue_number INTEGER,
    error_type TEXT,
    first_seen TEXT,
    last_seen TEXT,
    occurrence_count INTEGER DEFAULT 1,
    status TEXT DEFAULT 'open',
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_signature ON issues(signature);
CREATE INDEX IF NOT EXISTS idx_github_issue ON issues(github_issue_number);
CREATE INDEX IF NOT EXISTS idx_status ON issues(status);

CREATE TABLE IF NOT EXISTS error_occurrences (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    issue_id INTEGER,
    timestamp TEXT,
    error_data TEXT,
    FOREIGN KEY (issue_id) REFERENCES issues(id)
);

CREATE INDEX IF NOT EXISTS idx_issue_id ON error_occurrences(issue_id);
CREATE INDEX IF NOT EXISTS idx_timestamp ON error_occurrences(timestamp);
SQLEOF

# ==============================================================================
# DEDUPLICATION MANAGER
# ==============================================================================

cat > "$ERROR_REPORTING_DIR/dedup-manager.sh" << 'SHEOF'
#!/usr/bin/env bash
#
# Manages issue deduplication database
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
DB_PATH="$PROJECT_ROOT/.github/issue_cache.db"

init_database() {
    if [[ ! -f "$DB_PATH" ]]; then
        echo "Initializing deduplication database..."
        mkdir -p "$(dirname "$DB_PATH")"
        sqlite3 "$DB_PATH" < "$SCRIPT_DIR/init-dedup-db.sql"
        echo "Database initialized: $DB_PATH"
    fi
}

query_signature() {
    local signature="$1"

    if [[ ! -f "$DB_PATH" ]]; then
        return 1
    fi

    sqlite3 "$DB_PATH" \
        "SELECT github_issue_number, occurrence_count FROM issues WHERE signature = '$signature';"
}

record_occurrence() {
    local signature="$1"
    local error_type="$2"
    local github_issue="${3:-}"

    init_database

    # Check if exists
    local existing=$(sqlite3 "$DB_PATH" \
        "SELECT id FROM issues WHERE signature = '$signature';")

    if [[ -n "$existing" ]]; then
        # Update existing
        sqlite3 "$DB_PATH" <<SQL
UPDATE issues
SET last_seen = datetime('now'),
    occurrence_count = occurrence_count + 1
WHERE signature = '$signature';
SQL
    else
        # Insert new
        sqlite3 "$DB_PATH" <<SQL
INSERT INTO issues (signature, github_issue_number, error_type, first_seen, last_seen)
VALUES ('$signature', $github_issue, '$error_type', datetime('now'), datetime('now'));
SQL
    fi
}

list_all_issues() {
    if [[ ! -f "$DB_PATH" ]]; then
        echo "No database found"
        return
    fi

    sqlite3 -header -column "$DB_PATH" \
        "SELECT signature, github_issue_number, error_type, occurrence_count, status
         FROM issues
         ORDER BY last_seen DESC
         LIMIT 50;"
}

get_statistics() {
    if [[ ! -f "$DB_PATH" ]]; then
        echo "No database found"
        return
    fi

    echo "=== Issue Statistics ==="
    echo

    echo "Total unique errors:"
    sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM issues;"

    echo
    echo "Open issues:"
    sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM issues WHERE status = 'open';"

    echo
    echo "Total occurrences:"
    sqlite3 "$DB_PATH" "SELECT SUM(occurrence_count) FROM issues;"

    echo
    echo "Top 10 most frequent errors:"
    sqlite3 -header -column "$DB_PATH" \
        "SELECT error_type, occurrence_count, github_issue_number
         FROM issues
         ORDER BY occurrence_count DESC
         LIMIT 10;"
}

main() {
    local command="${1:-help}"

    case "$command" in
        init)
            init_database
            ;;
        query)
            query_signature "$2"
            ;;
        record)
            record_occurrence "$2" "$3" "$4"
            ;;
        list)
            list_all_issues
            ;;
        stats)
            get_statistics
            ;;
        help|*)
            cat <<EOF
xKOR_3RR0R Deduplication Manager

Usage: $0 <command> [args]

COMMANDS:
    init                Initialize database
    query <signature>   Query issue by signature
    record <sig> <type> [github_issue]  Record occurrence
    list                List all issues
    stats               Show statistics
    help                Show this help

EXAMPLES:
    $0 init
    $0 query abc123def456
    $0 record abc123def456 "frontend_crash" 42
    $0 list
    $0 stats

DATABASE:
    Location: $DB_PATH
EOF
            ;;
    esac
}

main "$@"
SHEOF

chmod +x "$ERROR_REPORTING_DIR/dedup-manager.sh"

# Initialize database
bash "$ERROR_REPORTING_DIR/dedup-manager.sh" init

echo "✓ Deduplication system created"
