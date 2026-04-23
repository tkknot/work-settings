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
    rsync -av --delete --exclude='AGENTS.md' "./.ai/" "$AI_DEST_DIR/"
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

# Claude Desktop MCP設定: ~/Library/Application Support/Claude/claude_desktop_config.json -> ~/.ai/mcp.json
# macOS上のClaude Desktopアプリが読み込むMCPサーバーの接続先定義
if [ -f "$AI_DEST_DIR/mcp.json" ] && [ "$(uname)" = "Darwin" ]; then
    CLAUDE_DESKTOP_CONFIG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
    mkdir -p "$(dirname "$CLAUDE_DESKTOP_CONFIG")"
    rm -f "$CLAUDE_DESKTOP_CONFIG"
    echo "Creating symlink: $CLAUDE_DESKTOP_CONFIG -> $AI_DEST_DIR/mcp.json"
    ln -s "$AI_DEST_DIR/mcp.json" "$CLAUDE_DESKTOP_CONFIG"
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

# WSL detection: also distribute to Windows user profile so that Windows-native
# Claude Code / Claude Desktop see the same config. We copy (not symlink) because
# symlinks created in /mnt/c from WSL are not recognized by native Windows apps.
if [ -f /proc/version ] && grep -qi Microsoft /proc/version; then
    WINDOWS_USER="taked"
    WINDOWS_HOME="/mnt/c/Users/$WINDOWS_USER"
    WIN_AI_DIR="$WINDOWS_HOME/.ai"
    WIN_CLAUDE_DIR="$WINDOWS_HOME/.claude"

    echo ""
    echo "=== WSL detected. Syncing to Windows: $WINDOWS_HOME ==="

    if [ ! -d "$WIN_AI_DIR" ]; then
        mkdir -p "$WIN_AI_DIR"
        rsync -av --delete --exclude='AGENTS.md' "./.ai/" "$WIN_AI_DIR/"
    fi

    mkdir -p "$WIN_CLAUDE_DIR"
    for dir in "${TARGET_DIRS[@]}"; do
        if [ -d "$WIN_AI_DIR/$dir" ]; then
            if [ -e "$WIN_CLAUDE_DIR/$dir" ] || [ -L "$WIN_CLAUDE_DIR/$dir" ]; then
                rm -rf "$WIN_CLAUDE_DIR/$dir"
            fi
            echo "Copying: $WIN_AI_DIR/$dir -> $WIN_CLAUDE_DIR/$dir"
            cp -r "$WIN_AI_DIR/$dir" "$WIN_CLAUDE_DIR/$dir"
        fi
    done

    # MCPサーバー設定: Windows側の %USERPROFILE%\.claude.json
    if [ -f "$WIN_AI_DIR/mcp.json" ]; then
        cp "$WIN_AI_DIR/mcp.json" "$WINDOWS_HOME/.claude.json"
        echo "Copied: $WIN_AI_DIR/mcp.json -> $WINDOWS_HOME/.claude.json"
    fi

    # Claude Desktop MCP設定: %APPDATA%\Claude\claude_desktop_config.json
    if [ -f "$WIN_AI_DIR/mcp.json" ]; then
        WIN_CLAUDE_DESKTOP="$WINDOWS_HOME/AppData/Roaming/Claude/claude_desktop_config.json"
        mkdir -p "$(dirname "$WIN_CLAUDE_DESKTOP")"
        cp "$WIN_AI_DIR/mcp.json" "$WIN_CLAUDE_DESKTOP"
        echo "Copied: $WIN_AI_DIR/mcp.json -> $WIN_CLAUDE_DESKTOP"
    fi

    if [ -f "$WIN_AI_DIR/playwright-config.json" ]; then
        cp "$WIN_AI_DIR/playwright-config.json" "$WIN_CLAUDE_DIR/playwright-config.json"
    fi

    if [ -f "$SCRIPT_DIR/.claude/settings.json" ]; then
        cp "$SCRIPT_DIR/.claude/settings.json" "$WIN_CLAUDE_DIR/settings.json"
        echo "Copied: $SCRIPT_DIR/.claude/settings.json -> $WIN_CLAUDE_DIR/settings.json"
    fi
fi

echo ""
echo "Claude sync complete!"
