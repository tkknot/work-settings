#!/bin/bash

# AGENTS.md / CLAUDE.md をホームディレクトリに配布する
# ~/.claude/CLAUDE.md と ~/.cursor/AGENTS.md に配置

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$SCRIPT_DIR/AGENTS.md"

echo "Syncing AGENTS.md..."

# Centralized location: ~/.ai/AGENTS.md
AI_DIR="$HOME/.ai"
mkdir -p "$AI_DIR"
cp "$SOURCE" "$AI_DIR/AGENTS.md"
echo "Copied -> $AI_DIR/AGENTS.md"

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

# WSL detection: also distribute to Windows user profile so that Windows-native
# Cursor / Claude Code / Claude Desktop see the same AGENTS.md
if [ -f /proc/version ] && grep -qi Microsoft /proc/version; then
    WINDOWS_USER="taked"
    WINDOWS_HOME="/mnt/c/Users/$WINDOWS_USER"

    echo ""
    echo "WSL detected. Syncing AGENTS.md to Windows: $WINDOWS_HOME"

    for sub in .ai .claude .cursor; do
        mkdir -p "$WINDOWS_HOME/$sub"
    done
    cp "$SOURCE" "$WINDOWS_HOME/.ai/AGENTS.md"
    cp "$SOURCE" "$WINDOWS_HOME/.claude/CLAUDE.md"
    cp "$SOURCE" "$WINDOWS_HOME/.cursor/AGENTS.md"
    echo "Copied -> $WINDOWS_HOME/.ai/AGENTS.md"
    echo "Copied -> $WINDOWS_HOME/.claude/CLAUDE.md"
    echo "Copied -> $WINDOWS_HOME/.cursor/AGENTS.md"
fi

echo "Done!"
