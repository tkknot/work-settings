#!/bin/bash

# WezTerm シェル統合（OSC 7 / OSC 133 / OSC 1337）と nvim 別タブ関数を配布する
# - shell/*.sh を ~/.config/ に配置
# - ~/.bashrc（および zsh 使用環境では ~/.zshrc）に source 行を冪等に追記（マーカーで重複防止）
#
# これにより以下が有効になる:
#   - OSC 7   : カレントディレクトリ通知
#   - OSC 133 : プロンプト/コマンドのセマンティックゾーン（LEADER+z のコピー等で使用）
#   - OSC 1337: ユーザー変数（nvim 別タブ起動の依頼に使用）
#
# wezterm-shell-integration.sh は公式由来で bash・zsh どちらでも動作する。
# nvim 関数（wezterm-nvim.sh）も bash/zsh 互換。

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INTEG_SRC="$SCRIPT_DIR/shell/wezterm-shell-integration.sh"
INTEG_DEST="$HOME/.config/wezterm-shell-integration.sh"
INTEG_MARKER="# >>> wezterm shell integration >>>"

NVIM_FN_SRC="$SCRIPT_DIR/shell/wezterm-nvim.sh"
NVIM_FN_DEST="$HOME/.config/wezterm-nvim.sh"
NVIM_FN_MARKER="# >>> wezterm nvim new-tab >>>"

if [ ! -f "$INTEG_SRC" ]; then
  echo "エラー: $INTEG_SRC が見つかりません。" >&2
  exit 1
fi

# --- 追記対象の rc ファイルを決める ---
# bash は常に対象。zsh は「~/.zshrc が存在する」「macOS（既定が zsh）」「ログインシェルが zsh」
# のいずれかで対象にする（無ければ ~/.zshrc を新規作成して追記）。
RC_FILES=("$HOME/.bashrc")
add_zsh=0
[ -f "$HOME/.zshrc" ] && add_zsh=1
[ "$(uname)" = "Darwin" ] && add_zsh=1
case "${SHELL:-}" in */zsh) add_zsh=1 ;; esac
[ "$add_zsh" = "1" ] && RC_FILES+=("$HOME/.zshrc")

# rc ファイルへ source ブロックを冪等に追記する
#   $1=rc ファイル, $2=open マーカー, $3=source 対象（リテラル $HOME 可）, $4=ラベル
append_source_block() {
  local rc="$1" marker="$2" target="$3" label="$4"
  local close="${marker//>>>/<<<}"
  if [ -f "$rc" ] && grep -qF "$marker" "$rc"; then
    echo "$rc には既に $label が設定されています。スキップします。"
    return
  fi
  {
    echo ""
    echo "$marker"
    echo "if [ -f \"$target\" ]; then"
    echo "  source \"$target\""
    echo "fi"
    echo "$close"
  } >>"$rc"
  echo "Added $label to $rc"
}

# --- スクリプト本体を配置 ---
mkdir -p "$HOME/.config"
cp "$INTEG_SRC" "$INTEG_DEST"
echo "Copied $INTEG_SRC -> $INTEG_DEST"
if [ -f "$NVIM_FN_SRC" ]; then
  cp "$NVIM_FN_SRC" "$NVIM_FN_DEST"
  echo "Copied $NVIM_FN_SRC -> $NVIM_FN_DEST"
fi

# --- 各 rc ファイルへ source 行を追記 ---
for rc in "${RC_FILES[@]}"; do
  append_source_block "$rc" "$INTEG_MARKER" '$HOME/.config/wezterm-shell-integration.sh' "WezTerm シェル統合"
  if [ -f "$NVIM_FN_SRC" ]; then
    append_source_block "$rc" "$NVIM_FN_MARKER" '$HOME/.config/wezterm-nvim.sh' "nvim new-tab 関数"
  fi
done

echo ""
echo "Done! 新しいシェルを開くか、'source ~/.bashrc'（zsh は 'source ~/.zshrc'）で反映されます。"
