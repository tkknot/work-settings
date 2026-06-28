#!/usr/bin/env bash
# WezTerm のペインを指定レイアウトに一発分割するスクリプト（CLI 用）。
# 使い方: wezterm-split.sh [2|2v|4]   （既定: 2）
#   2 / 2h … 左右 2 分割
#   2v     … 上下 2 分割
#   4      … 2x2 の田の字
# WezTerm のペイン内で実行すること（$WEZTERM_PANE を対象に分割する）。
set -euo pipefail

mode="${1:-2}"

# 分割で生まれるペインは常にホーム($HOME)で開く
# （WSL では指定しないと Windows 側 cwd にフォールバックするため明示する）
case "$mode" in
  4)
    # 右に分割して右ペインIDを取得 → 左右それぞれを下に分割し 2x2 を作る
    right=$(wezterm cli split-pane --right --percent 50 --cwd "$HOME")
    wezterm cli split-pane --bottom --percent 50 --cwd "$HOME" >/dev/null
    wezterm cli split-pane --bottom --percent 50 --pane-id "$right" --cwd "$HOME" >/dev/null
    ;;
  2|2h)
    wezterm cli split-pane --right --percent 50 --cwd "$HOME" >/dev/null
    ;;
  2v)
    wezterm cli split-pane --bottom --percent 50 --cwd "$HOME" >/dev/null
    ;;
  *)
    echo "Usage: wezterm-split.sh [2|2v|4]" >&2
    exit 1
    ;;
esac
