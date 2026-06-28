#!/bin/bash

# Claude Code / Claude Desktop 用の設定をホームディレクトリに配布する。
#
# 重要: ~/.claude.json は Claude Code 本体の状態ファイル（OAuthアカウント・プロジェクト
#       履歴・オンボーディング状態など）であり、MCP 設定専用ファイルではない。
#       過去はここを ~/.ai/mcp.json への symlink にしていたため、CC の状態書き込みが
#       symlink 越しに mcp.json を汚染していた。本スクリプトは ~/.claude.json を
#       symlink/上書きせず、MCP サーバーは `claude mcp add-json --scope user` で
#       CC 自身に安全に管理させる。

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_DEST_DIR="$HOME/.ai"
DEST_DIR="$HOME/.claude"

# ~/.claude/{rules,skills} -> ~/.ai/ の symlink で CC と Desktop が同じ定義を共有する
TARGET_DIRS=("rules" "skills")

# --- .ai を常に最新へ同期する ---
# 以前は「~/.ai が存在しないときだけ」同期していたため、mcp.json や skills の更新が
# 二度とホームへ反映されなかった。常に rsync して最新を保つ。
echo "Syncing .ai to $AI_DEST_DIR..."
mkdir -p "$AI_DEST_DIR"
rsync -av --delete --exclude='AGENTS.md' "$SCRIPT_DIR/.ai/" "$AI_DEST_DIR/"

echo "=== Creating symlinks in $DEST_DIR -> $AI_DEST_DIR ==="
mkdir -p "$DEST_DIR"

for dir in "${TARGET_DIRS[@]}"; do
    if [ -d "$AI_DEST_DIR/$dir" ]; then
        if [ -e "$DEST_DIR/$dir" ] || [ -L "$DEST_DIR/$dir" ]; then
            rm -rf "$DEST_DIR/$dir"
        fi
        ln -s "$AI_DEST_DIR/$dir" "$DEST_DIR/$dir"
        echo "Linked: $DEST_DIR/$dir -> $AI_DEST_DIR/$dir"
    else
        echo "Warning: $AI_DEST_DIR/$dir not found. Skipping."
    fi
done

# --- 旧 symlink の救済: ~/.claude.json が mcp.json への symlink なら実ファイル化する ---
# symlink のままだと CC の状態書き込みが mcp.json を汚染し続けるため、状態を保持した
# まま通常ファイルへ変換する（実体 ~/.ai/mcp.json はこのあと rsync 済みのクリーン版）。
if [ -L "$HOME/.claude.json" ]; then
    echo "Detected legacy symlink at ~/.claude.json; converting to a real state file."
    tmp="$(mktemp)"
    cp -L "$HOME/.claude.json" "$tmp"
    rm -f "$HOME/.claude.json"
    cp "$tmp" "$HOME/.claude.json"
    rm -f "$tmp"
fi

# --- MCP サーバーをユーザースコープに登録する（~/.claude.json には触れない）---
register_mcp_servers() {
    local mcp_file="$1"
    if ! command -v claude >/dev/null 2>&1; then
        echo "Warning: 'claude' CLI not found; skipping MCP user-scope registration."
        return 0
    fi
    if ! command -v jq >/dev/null 2>&1; then
        echo "Warning: 'jq' not found; skipping MCP user-scope registration."
        return 0
    fi
    local name cfg
    while IFS= read -r name; do
        cfg="$(jq -c --arg n "$name" '.mcpServers[$n]' "$mcp_file")"
        claude mcp remove "$name" --scope user >/dev/null 2>&1 || true
        if claude mcp add-json "$name" "$cfg" --scope user >/dev/null 2>&1; then
            echo "Registered MCP server (user scope): $name"
        else
            echo "Warning: failed to register MCP server: $name"
        fi
    done < <(jq -r '.mcpServers | keys[]' "$mcp_file")
}

if [ -f "$AI_DEST_DIR/mcp.json" ]; then
    register_mcp_servers "$AI_DEST_DIR/mcp.json"
fi

# --- Claude Desktop (macOS): 既存設定を壊さず mcpServers のみ merge する ---
if [ -f "$AI_DEST_DIR/mcp.json" ] && [ "$(uname)" = "Darwin" ]; then
    DESKTOP="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
    mkdir -p "$(dirname "$DESKTOP")"
    if [ -f "$DESKTOP" ] && command -v jq >/dev/null 2>&1; then
        tmp="$(mktemp)"
        jq -s '.[0] * {mcpServers: .[1].mcpServers}' "$DESKTOP" "$AI_DEST_DIR/mcp.json" >"$tmp" && mv "$tmp" "$DESKTOP"
    else
        cp "$AI_DEST_DIR/mcp.json" "$DESKTOP"
    fi
    echo "Updated Claude Desktop MCP config: $DESKTOP"
fi

# --- Playwright MCP 設定（状態ファイルではないので symlink で問題ない）---
if [ -f "$AI_DEST_DIR/playwright-config.json" ]; then
    rm -f "$DEST_DIR/playwright-config.json"
    ln -s "$AI_DEST_DIR/playwright-config.json" "$DEST_DIR/playwright-config.json"
    echo "Linked: $DEST_DIR/playwright-config.json -> $AI_DEST_DIR/playwright-config.json"
fi

# --- Claude Code 設定: settings.json をコピー（言語設定・実験フラグなど）---
if [ -f "$SCRIPT_DIR/.claude/settings.json" ]; then
    cp "$SCRIPT_DIR/.claude/settings.json" "$DEST_DIR/settings.json"
    echo "Copied settings.json -> $DEST_DIR/settings.json"
fi

# --- WSL: Windows ネイティブの CC / Desktop 向けにも配布する ---
# symlink は /mnt/c では機能しないためコピー。ただし %USERPROFILE%\.claude.json は
# Windows 側 CC の状態ファイルなので「上書きコピー」せず mcpServers のみ jq で merge する。
if [ -f /proc/version ] && grep -qi Microsoft /proc/version; then
    WINDOWS_USER="taked"
    WINDOWS_HOME="/mnt/c/Users/$WINDOWS_USER"
    WIN_AI_DIR="$WINDOWS_HOME/.ai"
    WIN_CLAUDE_DIR="$WINDOWS_HOME/.claude"

    echo ""
    echo "=== WSL detected. Syncing to Windows: $WINDOWS_HOME ==="

    mkdir -p "$WIN_AI_DIR"
    rsync -av --delete --exclude='AGENTS.md' "$SCRIPT_DIR/.ai/" "$WIN_AI_DIR/"

    mkdir -p "$WIN_CLAUDE_DIR"
    for dir in "${TARGET_DIRS[@]}"; do
        if [ -d "$WIN_AI_DIR/$dir" ]; then
            if [ -e "$WIN_CLAUDE_DIR/$dir" ] || [ -L "$WIN_CLAUDE_DIR/$dir" ]; then
                rm -rf "$WIN_CLAUDE_DIR/$dir"
            fi
            cp -r "$WIN_AI_DIR/$dir" "$WIN_CLAUDE_DIR/$dir"
            echo "Copied: $WIN_AI_DIR/$dir -> $WIN_CLAUDE_DIR/$dir"
        fi
    done

    # %USERPROFILE%\.claude.json: 状態を壊さず mcpServers のみ merge
    if [ -f "$WIN_AI_DIR/mcp.json" ] && command -v jq >/dev/null 2>&1; then
        WIN_CLAUDE_JSON="$WINDOWS_HOME/.claude.json"
        tmp="$(mktemp)"
        if [ -f "$WIN_CLAUDE_JSON" ]; then
            jq -s '.[0] * {mcpServers: .[1].mcpServers}' "$WIN_CLAUDE_JSON" "$WIN_AI_DIR/mcp.json" >"$tmp" && mv "$tmp" "$WIN_CLAUDE_JSON"
        else
            jq '{mcpServers: .mcpServers}' "$WIN_AI_DIR/mcp.json" >"$WIN_CLAUDE_JSON"
        fi
        echo "Merged mcpServers into: $WIN_CLAUDE_JSON"
    fi

    # Windows Claude Desktop: %APPDATA%\Claude\claude_desktop_config.json（状態を壊さず merge）
    if [ -f "$WIN_AI_DIR/mcp.json" ]; then
        WIN_CLAUDE_DESKTOP="$WINDOWS_HOME/AppData/Roaming/Claude/claude_desktop_config.json"
        mkdir -p "$(dirname "$WIN_CLAUDE_DESKTOP")"
        if [ -f "$WIN_CLAUDE_DESKTOP" ] && command -v jq >/dev/null 2>&1; then
            tmp="$(mktemp)"
            jq -s '.[0] * {mcpServers: .[1].mcpServers}' "$WIN_CLAUDE_DESKTOP" "$WIN_AI_DIR/mcp.json" >"$tmp" && mv "$tmp" "$WIN_CLAUDE_DESKTOP"
        else
            cp "$WIN_AI_DIR/mcp.json" "$WIN_CLAUDE_DESKTOP"
        fi
        echo "Updated Windows Claude Desktop MCP config: $WIN_CLAUDE_DESKTOP"
    fi

    if [ -f "$WIN_AI_DIR/playwright-config.json" ]; then
        cp "$WIN_AI_DIR/playwright-config.json" "$WIN_CLAUDE_DIR/playwright-config.json"
    fi

    if [ -f "$SCRIPT_DIR/.claude/settings.json" ]; then
        cp "$SCRIPT_DIR/.claude/settings.json" "$WIN_CLAUDE_DIR/settings.json"
        echo "Copied: settings.json -> $WIN_CLAUDE_DIR/settings.json"
    fi
fi

echo ""
echo "Claude sync complete!"
