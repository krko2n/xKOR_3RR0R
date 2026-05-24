#!/usr/bin/env bash
#
# Creates GitHub issue management system
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ERROR_REPORTING_DIR="$SCRIPT_DIR/error-reporting"

mkdir -p "$ERROR_REPORTING_DIR"

# ==============================================================================
# GITHUB ISSUE MANAGER
# ==============================================================================

cat > "$ERROR_REPORTING_DIR/github-issue-manager.py" << 'PYEOF'
#!/usr/bin/env python3
"""
xKOR_3RR0R - GitHub Issue Manager
Creates, updates, and deduplicates GitHub issues automatically
"""

import sys
import json
import sqlite3
import subprocess
from pathlib import Path
from datetime import datetime

class GitHubIssueManager:
    def __init__(self, project_root):
        self.project_root = Path(project_root)
        self.db_path = self.project_root / ".github" / "issue_cache.db"
        self.init_database()

    def init_database(self):
        """Initialize SQLite database for issue tracking"""
        self.db_path.parent.mkdir(parents=True, exist_ok=True)

        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        cursor.execute("""
            CREATE TABLE IF NOT EXISTS issues (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                signature TEXT UNIQUE NOT NULL,
                github_issue_number INTEGER,
                error_type TEXT,
                first_seen TEXT,
                last_seen TEXT,
                occurrence_count INTEGER DEFAULT 1,
                status TEXT DEFAULT 'open'
            )
        """)

        conn.commit()
        conn.close()

    def find_existing_issue(self, signature):
        """Find existing issue by signature"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        cursor.execute(
            "SELECT github_issue_number, occurrence_count FROM issues WHERE signature = ?",
            (signature,)
        )

        result = cursor.fetchone()
        conn.close()

        if result:
            return {"issue_number": result[0], "count": result[1]}
        return None

    def record_issue(self, signature, error_type, github_issue_number=None):
        """Record new issue or update existing"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        existing = self.find_existing_issue(signature)

        if existing:
            # Update existing
            cursor.execute("""
                UPDATE issues
                SET last_seen = ?,
                    occurrence_count = occurrence_count + 1
                WHERE signature = ?
            """, (datetime.now().isoformat(), signature))
        else:
            # Insert new
            cursor.execute("""
                INSERT INTO issues (signature, github_issue_number, error_type, first_seen, last_seen)
                VALUES (?, ?, ?, ?, ?)
            """, (
                signature,
                github_issue_number,
                error_type,
                datetime.now().isoformat(),
                datetime.now().isoformat()
            ))

        conn.commit()
        conn.close()

    def create_github_issue(self, title, body):
        """Create GitHub issue using gh CLI"""
        try:
            result = subprocess.run(
                ["gh", "issue", "create",
                 "--title", title,
                 "--body", body,
                 "--label", "bug,auto-report,crash"],
                capture_output=True,
                text=True,
                check=True
            )

            # Extract issue number from URL
            issue_url = result.stdout.strip()
            issue_number = int(issue_url.split("/")[-1])

            return issue_number

        except subprocess.CalledProcessError as e:
            print(f"Failed to create GitHub issue: {e}", file=sys.stderr)
            print(f"stderr: {e.stderr}", file=sys.stderr)
            return None

    def add_comment_to_issue(self, issue_number, comment):
        """Add comment to existing issue"""
        try:
            subprocess.run(
                ["gh", "issue", "comment", str(issue_number), "--body", comment],
                capture_output=True,
                text=True,
                check=True
            )
            return True
        except subprocess.CalledProcessError:
            return False

    def should_create_issue(self, signature):
        """Determine if new issue should be created based on rate limiting"""
        existing = self.find_existing_issue(signature)

        if not existing:
            return True  # New error, create issue

        # Rate limiting: only create new issue if last one is old enough
        # or if occurrence count is high
        count = existing.get("count", 0)

        if count >= 10:
            return False  # Too many occurrences, don't spam

        return False  # Reuse existing issue

    def handle_error_report(self, report_data):
        """Main handler for error reports"""
        signature = report_data["signature"]
        error_type = report_data["error_type"]
        markdown = report_data["markdown"]

        # Check if issue exists
        existing = self.find_existing_issue(signature)

        if existing and existing["issue_number"]:
            # Update existing issue
            issue_number = existing["issue_number"]
            count = existing["count"] + 1

            comment = f"""## Crash Report Update

**Occurrence:** #{count}
**Timestamp:** {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}

This error has occurred {count} times.

<details>
<summary>Latest crash details</summary>

{markdown}

</details>
"""
            self.add_comment_to_issue(issue_number, comment)
            self.record_issue(signature, error_type)

            return {
                "action": "updated",
                "issue_number": issue_number,
                "occurrence_count": count
            }
        else:
            # Create new issue
            title = f"[Auto] {error_type}: Crash Report"

            issue_number = self.create_github_issue(title, markdown)

            if issue_number:
                self.record_issue(signature, error_type, issue_number)

                return {
                    "action": "created",
                    "issue_number": issue_number,
                    "occurrence_count": 1
                }
            else:
                return {
                    "action": "failed",
                    "error": "Failed to create GitHub issue"
                }

def main():
    if len(sys.argv) < 2:
        print("Usage: github-issue-manager.py <report_json>")
        sys.exit(1)

    report_file = Path(sys.argv[1])
    if not report_file.exists():
        print(f"Report file not found: {report_file}")
        sys.exit(1)

    with open(report_file) as f:
        report_data = json.load(f)

    project_root = Path(__file__).parent.parent.parent

    manager = GitHubIssueManager(project_root)
    result = manager.handle_error_report(report_data)

    print(json.dumps(result, indent=2))

if __name__ == "__main__":
    main()
PYEOF

chmod +x "$ERROR_REPORTING_DIR/github-issue-manager.py"

# ==============================================================================
# WRAPPER SCRIPT
# ==============================================================================

cat > "$ERROR_REPORTING_DIR/report-error.sh" << 'SHEOF'
#!/usr/bin/env bash
#
# Main entry point for error reporting
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

log_info() {
    echo "[INFO] $*" >&2
}

log_error() {
    echo "[ERROR] $*" >&2
}

main() {
    local error_type="${1:-unknown}"
    local error_message="${2:-No message}"
    local stack_trace="${3:-}"

    log_info "Collecting error data..."

    # Collect error data
    local error_json=$(mktemp)
    bash "$SCRIPT_DIR/collect-error-data.sh" \
        "$error_type" \
        "$error_message" \
        "$stack_trace" > "$error_json"

    log_info "Generating error report..."

    # Generate markdown report
    local report_json=$(python3 "$SCRIPT_DIR/generate-error-report.py" "$error_json")

    if [[ -z "$report_json" ]]; then
        log_error "Failed to generate error report"
        rm -f "$error_json"
        exit 1
    fi

    # Save report JSON
    local report_file=$(mktemp)
    echo "$report_json" > "$report_file"

    log_info "Creating/updating GitHub issue..."

    # Create or update GitHub issue
    if command -v gh >/dev/null 2>&1; then
        local result=$(python3 "$SCRIPT_DIR/github-issue-manager.py" "$report_file")

        echo "$result"
        log_info "Error reported successfully"
    else
        log_error "GitHub CLI not found, skipping issue creation"
        log_info "Report saved locally: $(echo "$report_json" | jq -r .report_file)"
    fi

    # Cleanup
    rm -f "$error_json" "$report_file"
}

main "$@"
SHEOF

chmod +x "$ERROR_REPORTING_DIR/report-error.sh"

echo "✓ GitHub integration created in: $ERROR_REPORTING_DIR"
