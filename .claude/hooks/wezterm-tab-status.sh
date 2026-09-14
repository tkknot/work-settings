#!/usr/bin/env bash
# Claude Code の実行状態を WezTerm のタブ名にアイコンで出すためのフック。
#
# OSC 1337 SetUserVar=claude_tab_status=<状態> を pty(/dev/tty) へ書き、
# wezterm.lua の format-tab-title がそれを読んでタブ名の先頭にアイコンを前置する。
# 同じ方式の前例は shell/wezterm-nvim.sh の claude_open_nvim。
#
#   使い方: wezterm-tab-status.sh <run|wait|done|idle>
#
# 重要: stdout には絶対に何も書かない。UserPromptSubmit フックの plain-text stdout は
# Claude が読むコンテキストとして注入されるため、混入すると毎ターン汚染される。

# フックの JSON は使わないが、読み捨てないと呼び出し側が SIGPIPE になりうる
cat >/dev/null 2>&1

status="${1:-idle}"

# WezTerm 以外では何もしない（WSL でも TERM_PROGRAM は伝播する。shell/wezterm-nvim.sh と同じ判定）
[ "${TERM_PROGRAM:-}" = "WezTerm" ] || exit 0
command -v base64 >/dev/null 2>&1 || exit 0

# base64 は環境により折り返すため tr で改行を落とす。終端は wezterm-nvim.sh に合わせて BEL
b64="$(printf '%s' "$status" | base64 | tr -d '\n')"

# 制御端末を持たない場合に備え、リダイレクト失敗のエラーごと捨てる
{ printf '\033]1337;SetUserVar=claude_tab_status=%s\007' "$b64" >/dev/tty; } 2>/dev/null

exit 0
