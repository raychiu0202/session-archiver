#!/usr/bin/env bash
# Helper script: append a row to MANIFEST.md with proper escaping
# Usage: update_manifest.sh <session_id> <timestamp> <title> <relative_path> [archive_root]

set -e

# Configuration
ARCHIVE_ROOT="${5:-$HOME/Documents/my_ai_archive}"
MANIFEST="$ARCHIVE_ROOT/MANIFEST.md"
SESSION_ID="$1"
TIMESTAMP="$2"
TITLE="$3"
REL_PATH="$4"

mkdir -p "$(dirname "$MANIFEST")"

# Escape special characters for Markdown table
# Replace | with \| and escape backslashes
escape_for_table() {
    local input="$1"
    echo "$input" | sed 's/\\/\\\\/g; s/|/\\|/g'
}

ESCAPED_TITLE=$(escape_for_table "$TITLE")

# Check if MANIFEST exists and has proper header
if [ ! -f "$MANIFEST" ] || ! head -4 "$MANIFEST" | grep -q '|.*会话ID.*|'; then
    cat > "$MANIFEST" << 'HEADER'
# 会话存档清单

| 会话ID | 存档时间 | 标题/摘要 | 文件路径 |
|--------|----------|-----------|----------|
HEADER
fi

# Append new row
echo "| $SESSION_ID | $TIMESTAMP | $ESCAPED_TITLE | $REL_PATH |" >> "$MANIFEST"
