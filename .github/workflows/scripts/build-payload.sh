#!/usr/bin/env bash
# Build a staging directory (payload) with the target repo layout
# from this work-settings repo. See distribute-settings.yml for usage.

set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "usage: $0 <src_dir> <out_dir>" >&2
  exit 2
fi

SRC="$1"
OUT="$2"

if [ ! -d "$SRC/.ai" ]; then
  echo "error: $SRC/.ai does not exist" >&2
  exit 1
fi

mkdir -p "$OUT"

# agent: AGENTS.md -> target root
cp "$SRC/AGENTS.md" "$OUT/AGENTS.md"

# cursor: .ai/ content -> .cursor/ (excluding cursor ignore files which go to root)
mkdir -p "$OUT/.cursor"
rsync -a \
  --exclude='.cursorignore' \
  --exclude='.cursorindexingignore' \
  "$SRC/.ai/" "$OUT/.cursor/"

# claude: .ai/ content -> .claude/ + settings.json
mkdir -p "$OUT/.claude"
rsync -a \
  --exclude='.cursorignore' \
  --exclude='.cursorindexingignore' \
  "$SRC/.ai/" "$OUT/.claude/"
cp "$SRC/.claude/settings.json" "$OUT/.claude/settings.json"

# Root-level files
[ -f "$SRC/.ai/.cursorignore" ]         && cp "$SRC/.ai/.cursorignore"         "$OUT/.cursorignore"
[ -f "$SRC/.ai/.cursorindexingignore" ] && cp "$SRC/.ai/.cursorindexingignore" "$OUT/.cursorindexingignore"

# .mcp.json: project-level MCP config for Claude Code at repo root
cp "$SRC/.ai/mcp.json" "$OUT/.mcp.json"

echo "payload built at $OUT"
