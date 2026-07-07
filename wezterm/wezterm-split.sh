#!/usr/bin/env bash
# WezTerm のペインを 2 分割するスクリプト（CLI 用）。
# 使い方: wezterm-split.sh [2|2h|2v]   （既定: 2）
#   2 / 2h … 左右 2 分割
#   2v     … 上下 2 分割
# ペイン分割は 1 タブあたり 2 つまで。既に 2 ペインある場合はエラー終了する。
# WezTerm のペイン内で実行すること（$WEZTERM_PANE を対象に分割する）。
set -euo pipefail

mode="${1:-2}"

# 現在のタブのペイン数を数え、既に 2 ペインあれば分割しない
pane_id="${WEZTERM_PANE:?WezTerm のペイン内で実行してください}"
tab_id="$(wezterm cli list | awk -v p="$pane_id" 'NR > 1 && $3 == p { print $2 }')"
pane_count="$(wezterm cli list | awk -v t="$tab_id" 'NR > 1 && $2 == t { n++ } END { print n + 0 }')"
if [ "$pane_count" -ge 2 ]; then
  echo "ペイン分割は2つまでです（現在: ${pane_count} ペイン）" >&2
  exit 1
fi

# 分割で生まれるペインは常にホーム($HOME)で開く
# （WSL では指定しないと Windows 側 cwd にフォールバックするため明示する）
case "$mode" in
  2|2h)
    wezterm cli split-pane --right --percent 50 --cwd "$HOME" >/dev/null
    ;;
  2v)
    wezterm cli split-pane --bottom --percent 50 --cwd "$HOME" >/dev/null
    ;;
  *)
    echo "Usage: wezterm-split.sh [2|2h|2v]" >&2
    exit 1
    ;;
esac
