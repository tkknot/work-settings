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

if [ ! -d "$SRC/.claude" ]; then
  echo "error: $SRC/.claude does not exist" >&2
  exit 1
fi

mkdir -p "$OUT"

# CLAUDE.md -> target root
cp "$SRC/CLAUDE.md" "$OUT/CLAUDE.md"

# claude: .claude/ content -> .claude/
mkdir -p "$OUT/.claude"
rsync -a --exclude='settings.local.json' "$SRC/.claude/" "$OUT/.claude/"

# .mcp.json: project-level MCP config for Claude Code at repo root
cp "$SRC/.claude/mcp.json" "$OUT/.mcp.json"

echo "payload built at $OUT"
