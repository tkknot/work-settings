#!/bin/bash

# WezTerm シェル統合（OSC 7 / OSC 133 / OSC 1337）を配布する
# - shell/wezterm-shell-integration.sh を ~/.config/ に配置
# - ~/.bashrc に source 行を冪等に追記（マーカーで重複防止）
#
# これにより以下が有効になる:
#   - OSC 7   : カレントディレクトリ通知
#   - OSC 133 : プロンプト/コマンドのセマンティックゾーン（LEADER+z のコピー等で使用）
#   - OSC 1337: ユーザー変数
#
# 注意: bash 用。zsh 等を使う場合は各自 rc に source 行を追加すること。

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_FILE="$SCRIPT_DIR/shell/wezterm-shell-integration.sh"
DEST_FILE="$HOME/.config/wezterm-shell-integration.sh"
BASHRC="$HOME/.bashrc"
MARKER="# >>> wezterm shell integration >>>"

if [ ! -f "$SOURCE_FILE" ]; then
  echo "エラー: $SOURCE_FILE が見つかりません。" >&2
  exit 1
fi

# --- スクリプト本体を配置 ---
mkdir -p "$HOME/.config"
cp "$SOURCE_FILE" "$DEST_FILE"
echo "Copied $SOURCE_FILE -> $DEST_FILE"

# --- ~/.bashrc に source 行を冪等に追記 ---
if [ -f "$BASHRC" ] && grep -qF "$MARKER" "$BASHRC"; then
  echo "~/.bashrc には既に WezTerm シェル統合が設定されています。スキップします。"
else
  {
    echo ""
    echo "$MARKER"
    echo "if [ -f \"\$HOME/.config/wezterm-shell-integration.sh\" ]; then"
    echo "  source \"\$HOME/.config/wezterm-shell-integration.sh\""
    echo "fi"
    echo "# <<< wezterm shell integration <<<"
  } >>"$BASHRC"
  echo "Added WezTerm シェル統合 to $BASHRC"
fi

echo ""
echo "Done! 新しいシェルを開くか 'source ~/.bashrc' で反映されます。"
