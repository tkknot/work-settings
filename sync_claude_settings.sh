#!/bin/bash

# Create symlinks for .claude pointing to ~/.ai
# Requires: sync_cursor_settings.sh (or equivalent) to have synced .ai to ~/.ai first

AI_DEST_DIR="$HOME/.ai"
DEST_DIR="$HOME/.claude"

# Claude Codeが参照するディレクトリ群
# ~/.claude/{agents,commands,rules,skills} -> ~/.ai/ のシンボリックリンクにして
# Claude CodeとCursorで同じ定義を共有する
TARGET_DIRS=("agents" "commands" "rules" "skills")

# Sync .ai if not already done
if [ ! -d "$AI_DEST_DIR" ]; then
    echo "Syncing .ai to $AI_DEST_DIR first..."
    mkdir -p "$AI_DEST_DIR"
    rsync -av --delete "./.ai/" "$AI_DEST_DIR/"
fi

echo "=== Creating symlinks in $DEST_DIR -> $AI_DEST_DIR ==="
mkdir -p "$DEST_DIR"

for dir in "${TARGET_DIRS[@]}"; do
    if [ -d "$AI_DEST_DIR/$dir" ]; then
        if [ -e "$DEST_DIR/$dir" ] || [ -L "$DEST_DIR/$dir" ]; then
            echo "Removing existing $DEST_DIR/$dir..."
            rm -rf "$DEST_DIR/$dir"
        fi
        echo "Creating symlink: $DEST_DIR/$dir -> $AI_DEST_DIR/$dir"
        ln -s "$AI_DEST_DIR/$dir" "$DEST_DIR/$dir"
    else
        echo "Warning: $AI_DEST_DIR/$dir not found. Skipping."
    fi
done

# MCPサーバー設定: ~/.claude.json -> ~/.ai/mcp.json
# Claude Codeが起動時に読み込むMCPサーバーの接続先定義
if [ -f "$AI_DEST_DIR/mcp.json" ]; then
    rm -f "$HOME/.claude.json"
    echo "Creating symlink: $HOME/.claude.json -> $AI_DEST_DIR/mcp.json"
    ln -s "$AI_DEST_DIR/mcp.json" "$HOME/.claude.json"
fi

# Playwright MCP設定: ~/.claude/playwright-config.json -> ~/.ai/playwright-config.json
# Playwright MCPサーバーが参照するブラウザ設定
if [ -f "$AI_DEST_DIR/playwright-config.json" ]; then
    rm -f "$DEST_DIR/playwright-config.json"
    echo "Creating symlink: $DEST_DIR/playwright-config.json -> $AI_DEST_DIR/playwright-config.json"
    ln -s "$AI_DEST_DIR/playwright-config.json" "$DEST_DIR/playwright-config.json"
fi

# Claude Code設定: settings.json をコピー（シンボリックリンクではなくコピー）
# 言語設定、実験的機能フラグなどのClaude Code固有設定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.claude/settings.json" ]; then
    echo "Copying settings.json -> $DEST_DIR/settings.json"
    cp "$SCRIPT_DIR/.claude/settings.json" "$DEST_DIR/settings.json"
fi

echo ""
echo "Claude sync complete!"
