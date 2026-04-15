#!/usr/bin/env bash
# Helper script: append a row to MANIFEST.md
# Usage: update_manifest.sh <session_id> <timestamp> <title> <relative_path>

MANIFEST="$HOME/.my_ai_archive/MANIFEST.md"
SESSION_ID="$1"
TIMESTAMP="$2"
TITLE="$3"
REL_PATH="$4"

mkdir -p "$(dirname "$MANIFEST")"

if [ ! -f "$MANIFEST" ] || ! head -4 "$MANIFEST" | grep -q '|.*会话ID.*|'; then
  cat > "$MANIFEST" << 'HEADER'
# 会话存档清单

| 会话ID | 存档时间 | 标题/摘要 | 文件路径 |
|--------|----------|-----------|----------|
HEADER
fi

echo "| $SESSION_ID | $TIMESTAMP | $TITLE | $REL_PATH |" >> "$MANIFEST"
