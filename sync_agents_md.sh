#!/bin/bash

# AGENTS.md / CLAUDE.md をホームディレクトリに配布する
# ~/.claude/CLAUDE.md と ~/.cursor/AGENTS.md に配置

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$SCRIPT_DIR/AGENTS.md"

echo "Syncing AGENTS.md..."

# Claude Code: ~/.claude/CLAUDE.md
CLAUDE_DIR="$HOME/.claude"
mkdir -p "$CLAUDE_DIR"
cp "$SOURCE" "$CLAUDE_DIR/CLAUDE.md"
echo "Copied -> $CLAUDE_DIR/CLAUDE.md"

# Cursor: ~/.cursor/AGENTS.md
CURSOR_DIR="$HOME/.cursor"
mkdir -p "$CURSOR_DIR"
cp "$SOURCE" "$CURSOR_DIR/AGENTS.md"
echo "Copied -> $CURSOR_DIR/AGENTS.md"

echo "Done!"
