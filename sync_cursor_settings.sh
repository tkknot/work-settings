#!/bin/bash

# Sync .ai settings first, then create symlinks for .cursor

# Step 1: Sync .ai to ~/.ai
AI_SOURCE_DIR="./.ai"
AI_DEST_DIR="$HOME/.ai"

echo "=== Syncing .ai to $AI_DEST_DIR ==="
mkdir -p "$AI_DEST_DIR"
rsync -av --delete "$AI_SOURCE_DIR/" "$AI_DEST_DIR/"
echo ".ai sync complete!"

# Step 2: Create symlinks in ~/.cursor pointing to ~/.ai
DEST_DIR="$HOME/.cursor"

# Cursorが参照するディレクトリ群
# ~/.cursor/{agents,commands,rules,skills} -> ~/.ai/ のシンボリックリンクにして
# CursorとClaude Codeで同じ定義を共有する
TARGET_DIRS=("agents" "commands" "rules" "skills")

echo ""
echo "=== Creating symlinks in $DEST_DIR -> $AI_DEST_DIR ==="
mkdir -p "$DEST_DIR"

for dir in "${TARGET_DIRS[@]}"; do
    if [ -d "$AI_DEST_DIR/$dir" ]; then
        # Remove existing directory or symlink
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

# MCPサーバー設定: ~/.cursor/mcp.json -> ~/.ai/mcp.json
# Cursorが起動時に読み込むMCPサーバーの接続先定義
if [ -f "$AI_DEST_DIR/mcp.json" ]; then
    rm -f "$DEST_DIR/mcp.json"
    echo "Creating symlink: $DEST_DIR/mcp.json -> $AI_DEST_DIR/mcp.json"
    ln -s "$AI_DEST_DIR/mcp.json" "$DEST_DIR/mcp.json"
fi

# Playwright MCP設定: ~/.cursor/playwright-config.json -> ~/.ai/playwright-config.json
# Playwright MCPサーバーが参照するブラウザ設定
if [ -f "$AI_DEST_DIR/playwright-config.json" ]; then
    rm -f "$DEST_DIR/playwright-config.json"
    echo "Creating symlink: $DEST_DIR/playwright-config.json -> $AI_DEST_DIR/playwright-config.json"
    ln -s "$AI_DEST_DIR/playwright-config.json" "$DEST_DIR/playwright-config.json"
fi

# Cursorの除外設定: ~/.cursor/.cursorignore -> ~/.ai/.cursorignore
# Cursorが無視するファイルパターン（ロックファイル、バイナリ等）
if [ -f "$AI_DEST_DIR/.cursorignore" ]; then
    rm -f "$DEST_DIR/.cursorignore"
    echo "Creating symlink: $DEST_DIR/.cursorignore -> $AI_DEST_DIR/.cursorignore"
    ln -s "$AI_DEST_DIR/.cursorignore" "$DEST_DIR/.cursorignore"
fi

# Cursorのインデックス除外設定: ~/.cursor/.cursorindexignore -> ~/.ai/.cursorindexignore
# Cursorの検索インデックスから除外するファイルパターン
if [ -f "$AI_DEST_DIR/.cursorindexignore" ]; then
    rm -f "$DEST_DIR/.cursorindexignore"
    echo "Creating symlink: $DEST_DIR/.cursorindexignore -> $AI_DEST_DIR/.cursorindexignore"
    ln -s "$AI_DEST_DIR/.cursorindexignore" "$DEST_DIR/.cursorindexignore"
fi

echo ""
echo "Cursor sync complete!"
