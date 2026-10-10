#!/bin/bash

# Claude Desktop（Code タブ / Chat）用の設定をホームディレクトリに配布する。
#
# 重要: ~/.claude.json は Claude Code 本体（Desktop 同梱分を含む）の状態ファイル（OAuth
#       アカウント・プロジェクト履歴・オンボーディング状態など）であり、MCP 設定専用ファイル
#       ではない。過去はここを mcp.json への symlink にしていたため、状態書き込みが symlink
#       越しに mcp.json を汚染していた。本スクリプトは ~/.claude.json を書き換えず、MCP
#       サーバーは claude_desktop_config.json に配る（Desktop の Chat と Code タブの両方が読む）。
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

# --- Claude Desktop: claude_desktop_config.json へ mcpServers を merge する ---
# Desktop の Chat と Code タブの両方がこのファイルの MCP を読む。Code タブは同名サーバーが
# ~/.claude.json にあってもこちらの定義を優先するため、ここが壊れると Code タブも壊れる。
# - 秘密を含まないサーバー（Playwright・context7 など）は repo の定義で上書きする。既存優先に
#   すると、過去の sync で入った壊れた定義が残り続けて repo 側の修正が反映されないため。
#   mcpServers 以外のキー（preferences などアプリが書く状態）はそのまま残す。
# - env にプレースホルダー（空文字・"your-" 始まり）が残るサーバーは追加も上書きもしない（実トークン
#   入りの既存定義を潰さない）。既存のプレースホルダー入りエントリは消さずに警告だけ出す
#   （Settings → Developer → Edit Config で実値に直す）。
# - Playwright の --config 相対パスは起動 cwd 基準で解決できず接続に失敗するため、既存エントリも
#   含めて絶対パスへ置換する（何度実行しても同じ結果になる）。
# - Windows の npx は npx.cmd で、Desktop は cmd /c を介さないと起動できず接続に失敗する
#   （Context7 公式の Windows 設定例と同じ）。$3 = windows のとき npx を cmd /c npx に包む（冪等）。
# 引数: $1 = 対象ファイル, $2 = Desktop から見た playwright-config.json の絶対パス, $3 = OS（省略可。windows）
merge_desktop_mcp() {
    local target="$1" playwright_cfg="$2" os="${3:-}" mcp_file="$SCRIPT_DIR/.claude/mcp.json"
    if ! command -v jq >/dev/null 2>&1; then
        echo "Warning: 'jq' not found; skipping Claude Desktop MCP merge: $target"
        return 0
    fi

    local current='{}'
    if [ -s "$target" ]; then
        current="$(cat "$target")"
    fi

    local defs='
        def placeholder: (.env // {}) | to_entries
            | any(.value == "" or (.value | tostring | startswith("your-")));'

    mkdir -p "$(dirname "$target")"
    local tmp
    tmp="$(mktemp)"
    if ! jq --argjson cur "$current" --arg pw "$playwright_cfg" --arg os "$os" "$defs"'
        def fix_playwright: if has("args") then
            .args |= map(if . == ".claude/playwright-config.json" then $pw else . end) else . end;
        def wrap_windows: if $os == "windows" and .command == "npx"
            then .command = "cmd" | .args = ["/c", "npx"] + (.args // []) else . end;
        (.mcpServers | with_entries(select(.value | placeholder | not))) as $add
        | $cur | .mcpServers = (((.mcpServers // {}) + $add) | map_values(fix_playwright | wrap_windows))
    ' "$mcp_file" >"$tmp"; then
        # 既存ファイルが壊れた JSON などで merge できない場合は触らない
        rm -f "$tmp"
        echo "Warning: failed to merge MCP servers; left unchanged: $target"
        return 0
    fi
    mv "$tmp" "$target"
    echo "Merged mcpServers into: $target"

    local name
    while IFS= read -r name; do
        echo "  Skipped (placeholder in mcp.json; add it in Desktop with real values): $name"
    done < <(jq -r --argjson cur "$current" "$defs"'
        .mcpServers | to_entries[] | .key as $k
        | select((.value | placeholder) and (($cur.mcpServers // {}) | has($k) | not)) | $k
    ' "$mcp_file")
    while IFS= read -r name; do
        echo "  Warning: placeholder values remain in: $name (replace them with real values)"
    done < <(jq -r "$defs"'
        .mcpServers | to_entries[] | select(.value | placeholder) | .key
    ' "$target")
}

if [ -f "$SCRIPT_DIR/.claude/mcp.json" ] && [ "$(uname)" = "Darwin" ]; then
    merge_desktop_mcp "$HOME/Library/Application Support/Claude/claude_desktop_config.json" \
        "$DEST_DIR/playwright-config.json"
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

# --- WSL: Windows ネイティブの Desktop 向けにも配布する ---
# symlink は /mnt/c では機能しないためコピー。
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

    # Windows Claude Desktop: %APPDATA%\Claude\claude_desktop_config.json
    # Desktop は Windows 側の npx で MCP を起動するため、Playwright の設定パスは Windows 形式で渡し、
    # npx は cmd /c で包む。
    if [ -f "$SCRIPT_DIR/.claude/mcp.json" ]; then
        merge_desktop_mcp "$WINDOWS_HOME/AppData/Roaming/Claude/claude_desktop_config.json" \
            "C:/Users/$WINDOWS_USER/.claude/playwright-config.json" windows
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
