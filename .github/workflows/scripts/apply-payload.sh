#!/usr/bin/env bash
# Apply a staging payload to a target repo working tree.
# Overwrites AGENTS.md, .cursorignore, .cursorindexingignore, .mcp.json;
# For .cursor/ and .claude/, uses add/update-only rsync (no --delete) so
# that files unique to the target repo (not managed by work-settings) are
# preserved.

set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "usage: $0 <payload_dir> <target_dir>" >&2
  exit 2
fi

PAYLOAD="$1"
TARGET="$2"

if [ ! -d "$PAYLOAD" ]; then
  echo "error: payload dir $PAYLOAD does not exist" >&2
  exit 1
fi
if [ ! -d "$TARGET" ]; then
  echo "error: target dir $TARGET does not exist" >&2
  exit 1
fi

# AGENTS.md (root)
if [ -f "$PAYLOAD/AGENTS.md" ]; then
  cp "$PAYLOAD/AGENTS.md" "$TARGET/AGENTS.md"
fi

# .cursor/ : add/update only (preserves target-only files)
if [ -d "$PAYLOAD/.cursor" ]; then
  mkdir -p "$TARGET/.cursor"
  rsync -a "$PAYLOAD/.cursor/" "$TARGET/.cursor/"
fi

# .claude/ : add/update only (preserves target-only files)
if [ -d "$PAYLOAD/.claude" ]; then
  mkdir -p "$TARGET/.claude"
  rsync -a "$PAYLOAD/.claude/" "$TARGET/.claude/"
fi

# Root-level single files
[ -f "$PAYLOAD/.cursorignore" ]         && cp "$PAYLOAD/.cursorignore"         "$TARGET/.cursorignore"
[ -f "$PAYLOAD/.cursorindexingignore" ] && cp "$PAYLOAD/.cursorindexingignore" "$TARGET/.cursorindexingignore"
[ -f "$PAYLOAD/.mcp.json" ]             && cp "$PAYLOAD/.mcp.json"             "$TARGET/.mcp.json"

echo "payload applied to $TARGET"
