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

# claude: .ai/ content -> .claude/ + settings.json
mkdir -p "$OUT/.claude"
rsync -a "$SRC/.ai/" "$OUT/.claude/"
cp "$SRC/.claude/settings.json" "$OUT/.claude/settings.json"

# .mcp.json: project-level MCP config for Claude Code at repo root
cp "$SRC/.ai/mcp.json" "$OUT/.mcp.json"

echo "payload built at $OUT"
