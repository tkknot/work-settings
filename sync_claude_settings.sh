#!/bin/bash

# Claude Code / Claude Desktop 用の設定をホームディレクトリに配布する。
#
# 重要: ~/.claude.json は Claude Code 本体の状態ファイル（OAuthアカウント・プロジェクト
#       履歴・オンボーディング状態など）であり、MCP 設定専用ファイルではない。
#       過去はここを mcp.json への symlink にしていたため、CC の状態書き込みが
#       symlink 越しに mcp.json を汚染していた。本スクリプトは ~/.claude.json を
#       symlink/上書きせず、MCP サーバーは `claude mcp add-json --scope user` で
#       CC 自身に安全に管理させる。
#
# 重要: ~/.claude/ は Claude Code 本体の状態ディレクトリ（projects/, plans/,
#       sessions/, .credentials.json, settings.local.json 等）と同居している。
#       トップレベルで --delete を使うとこれらを全滅させるため、本スクリプトは
#       リポジトリが所有するサブディレクトリ・ファイル単位でのみ同期する。

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_DIR="$HOME/.claude"

# リポジトリが所有し、丸ごと同期して問題ないサブディレクトリ
REPO_DIRS=("skills" "rules" "hooks" "commands")

# --- 旧 symlink の解除 ---
# 以前は ~/.claude/{rules,skills,playwright-config.json} を ~/.ai/ への symlink に
# していた。解除せずに rsync すると symlink を辿って ~/.ai/ 側に書き込まれてしまうため、
# 同期の前に必ず解除する（冪等）。
for p in "${REPO_DIRS[@]}" "playwright-config.json"; do
    if [ -L "$DEST_DIR/$p" ]; then
        echo "Removing legacy symlink: $DEST_DIR/$p"
        rm -f "$DEST_DIR/$p"
    fi
done

mkdir -p "$DEST_DIR"

echo "=== Syncing .claude/{skills,rules,hooks,commands} -> $DEST_DIR ==="
for dir in "${REPO_DIRS[@]}"; do
    if [ -d "$SCRIPT_DIR/.claude/$dir" ]; then
        mkdir -p "$DEST_DIR/$dir"
        rsync -a --delete "$SCRIPT_DIR/.claude/$dir/" "$DEST_DIR/$dir/"
        echo "Synced: $DEST_DIR/$dir"
    else
        echo "Warning: $SCRIPT_DIR/.claude/$dir not found. Skipping."
    fi
done

# --- 旧 symlink の救済: ~/.claude.json が mcp.json への symlink なら実ファイル化する ---
# symlink のままだと CC の状態書き込みが mcp.json を汚染し続けるため、状態を保持した
# まま通常ファイルへ変換する。
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
        # 既に登録済み（任意スコープ）なら上書きせずスキップ。削除/無効化は手動運用。
        if claude mcp get "$name" >/dev/null 2>&1; then
            echo "Skipped (already registered): $name"
            continue
        fi
        # Playwright の --config 相対パスは CC 起動 cwd 基準で解決できず接続失敗するため、
        # ホームの絶対パス（$DEST_DIR/playwright-config.json）へ置換する。
        cfg="$(jq -c --arg n "$name" --arg cfgdir "$DEST_DIR" '
            .mcpServers[$n]
            | if has("args") then
                .args |= map(if . == ".claude/playwright-config.json"
                             then $cfgdir + "/playwright-config.json" else . end)
              else . end' "$mcp_file")"
        if claude mcp add-json "$name" "$cfg" --scope user >/dev/null 2>&1; then
            echo "Registered MCP server (user scope): $name"
        else
            echo "Warning: failed to register MCP server: $name"
        fi
    done < <(jq -r '.mcpServers | keys[]' "$mcp_file")
}

if [ -f "$SCRIPT_DIR/.claude/mcp.json" ]; then
    register_mcp_servers "$SCRIPT_DIR/.claude/mcp.json"
fi

# --- Claude Desktop (macOS): 既存設定を壊さず mcpServers のみ merge する ---
if [ -f "$SCRIPT_DIR/.claude/mcp.json" ] && [ "$(uname)" = "Darwin" ]; then
    DESKTOP="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
    mkdir -p "$(dirname "$DESKTOP")"
    if [ -f "$DESKTOP" ] && command -v jq >/dev/null 2>&1; then
        tmp="$(mktemp)"
        jq -s '.[0] * {mcpServers: .[1].mcpServers}' "$DESKTOP" "$SCRIPT_DIR/.claude/mcp.json" >"$tmp" && mv "$tmp" "$DESKTOP"
    else
        cp "$SCRIPT_DIR/.claude/mcp.json" "$DESKTOP"
    fi
    echo "Updated Claude Desktop MCP config: $DESKTOP"
fi

# --- Playwright MCP 設定を実ファイルとして配置 ---
if [ -f "$SCRIPT_DIR/.claude/playwright-config.json" ]; then
    cp "$SCRIPT_DIR/.claude/playwright-config.json" "$DEST_DIR/playwright-config.json"
    echo "Copied: $DEST_DIR/playwright-config.json"
fi

# --- Claude Code 設定: settings.json をコピー（言語設定・実験フラグなど）---
if [ -f "$SCRIPT_DIR/.claude/settings.json" ]; then
    cp "$SCRIPT_DIR/.claude/settings.json" "$DEST_DIR/settings.json"
    echo "Copied settings.json -> $DEST_DIR/settings.json"
fi

# --- エージェントガイドライン: CLAUDE.md をコピー ---
if [ -f "$SCRIPT_DIR/CLAUDE.md" ]; then
    cp "$SCRIPT_DIR/CLAUDE.md" "$DEST_DIR/CLAUDE.md"
    echo "Copied: CLAUDE.md -> $DEST_DIR/CLAUDE.md"
fi

# --- WSL: Windows ネイティブの CC / Desktop 向けにも配布する ---
# symlink は /mnt/c では機能しないためコピー。ただし %USERPROFILE%\.claude.json は
# Windows 側 CC の状態ファイルなので「上書きコピー」せず mcpServers のみ jq で merge する。
if [ -f /proc/version ] && grep -qi Microsoft /proc/version; then
    WINDOWS_USER="taked"
    WINDOWS_HOME="/mnt/c/Users/$WINDOWS_USER"
    WIN_CLAUDE_DIR="$WINDOWS_HOME/.claude"

    echo ""
    echo "=== WSL detected. Syncing to Windows: $WINDOWS_HOME ==="

    mkdir -p "$WIN_CLAUDE_DIR"
    for dir in "${REPO_DIRS[@]}"; do
        if [ -d "$SCRIPT_DIR/.claude/$dir" ]; then
            mkdir -p "$WIN_CLAUDE_DIR/$dir"
            rsync -a --delete "$SCRIPT_DIR/.claude/$dir/" "$WIN_CLAUDE_DIR/$dir/"
            echo "Synced: $WIN_CLAUDE_DIR/$dir"
        fi
    done

    # %USERPROFILE%\.claude.json: 状態を壊さず mcpServers のみ merge
    if [ -f "$SCRIPT_DIR/.claude/mcp.json" ] && command -v jq >/dev/null 2>&1; then
        WIN_CLAUDE_JSON="$WINDOWS_HOME/.claude.json"
        tmp="$(mktemp)"
        if [ -f "$WIN_CLAUDE_JSON" ]; then
            # 既存登録は上書きせず新規サーバーのみ追加（キー衝突時は既存=.[0] が勝つ）。削除は手動運用。
            jq -s '.[0] + {mcpServers: (.[1].mcpServers + (.[0].mcpServers // {}))}' "$WIN_CLAUDE_JSON" "$SCRIPT_DIR/.claude/mcp.json" >"$tmp" && mv "$tmp" "$WIN_CLAUDE_JSON"
        else
            jq '{mcpServers: .mcpServers}' "$SCRIPT_DIR/.claude/mcp.json" >"$WIN_CLAUDE_JSON"
        fi
        echo "Merged mcpServers into: $WIN_CLAUDE_JSON"
    fi

    # Windows Claude Desktop: %APPDATA%\Claude\claude_desktop_config.json（状態を壊さず merge）
    if [ -f "$SCRIPT_DIR/.claude/mcp.json" ]; then
        WIN_CLAUDE_DESKTOP="$WINDOWS_HOME/AppData/Roaming/Claude/claude_desktop_config.json"
        mkdir -p "$(dirname "$WIN_CLAUDE_DESKTOP")"
        if [ -f "$WIN_CLAUDE_DESKTOP" ] && command -v jq >/dev/null 2>&1; then
            tmp="$(mktemp)"
            jq -s '.[0] * {mcpServers: .[1].mcpServers}' "$WIN_CLAUDE_DESKTOP" "$SCRIPT_DIR/.claude/mcp.json" >"$tmp" && mv "$tmp" "$WIN_CLAUDE_DESKTOP"
        else
            cp "$SCRIPT_DIR/.claude/mcp.json" "$WIN_CLAUDE_DESKTOP"
        fi
        echo "Updated Windows Claude Desktop MCP config: $WIN_CLAUDE_DESKTOP"
    fi

    if [ -f "$SCRIPT_DIR/.claude/playwright-config.json" ]; then
        cp "$SCRIPT_DIR/.claude/playwright-config.json" "$WIN_CLAUDE_DIR/playwright-config.json"
    fi

    if [ -f "$SCRIPT_DIR/.claude/settings.json" ]; then
        cp "$SCRIPT_DIR/.claude/settings.json" "$WIN_CLAUDE_DIR/settings.json"
        echo "Copied: settings.json -> $WIN_CLAUDE_DIR/settings.json"
    fi

    if [ -f "$SCRIPT_DIR/CLAUDE.md" ]; then
        cp "$SCRIPT_DIR/CLAUDE.md" "$WIN_CLAUDE_DIR/CLAUDE.md"
        echo "Copied: CLAUDE.md -> $WIN_CLAUDE_DIR/CLAUDE.md"
    fi
fi

echo ""
echo "Claude sync complete!"
