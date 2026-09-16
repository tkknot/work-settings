#!/usr/bin/env bash
# Stop フック: ターン終了時に context 使用率 / レート制限 / cost を systemMessage で表示する。
#
# context_window と rate_limits は statusLine の payload にしか入らないので、statusline.sh が
# 書いた state ファイルを読む。Stop 自身の payload にはこれらは入っていない。
#
# なぜ Stop なのか: SessionEnd はユーザー表示もコンテキスト注入もできず（かつ全 hook で
# 1.5 秒の共有予算）、使用量を見せる先にならない。Stop は systemMessage で画面に出せる。
#
# stdout には JSON だけを書く。state が無い・空・古い場合は完全に無音で抜ける。

set -u

input="$(cat)"

command -v jq >/dev/null 2>&1 || exit 0

sid="$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)"
[ -n "$sid" ] || exit 0

state_file="${XDG_STATE_HOME:-$HOME/.local/state}/claude-code/session-${sid}.env"
[ -f "$state_file" ] || exit 0

# state は自分で書いたものだが、source せず grep で読む（設定ファイルを実行しない）
val_of() { grep -m1 "^$1=" "$state_file" 2>/dev/null | cut -d= -f2-; }

ctx="$(val_of CC_CTX_PCT)"
cost="$(val_of CC_COST_USD)"
h5="$(val_of CC_RL_5H_PCT)"
d7="$(val_of CC_RL_7D_PCT)"
updated="$(val_of CC_UPDATED_AT)"

# 古い state は出さない（別セッションの残骸や、初回 API 応答前の空を拾わないため）
now="$(date +%s)"
if [ -n "$updated" ] && [ $((now - updated)) -gt 300 ] 2>/dev/null; then
    exit 0
fi

parts=""
add() { [ -n "$1" ] && parts="${parts:+$parts | }$2"; }
add "$ctx"  "ctx ${ctx}%"
add "$h5"   "5h ${h5}%"
add "$d7"   "週 ${d7}%"
[ -n "$cost" ] && parts="${parts:+$parts | }$(printf '$%.2f' "$cost" 2>/dev/null)"

# 表示するものが何も無ければ黙る
[ -n "$parts" ] || exit 0

jq -nc --arg msg "$parts" \
  '{hookSpecificOutput:{hookEventName:"Stop",systemMessage:$msg}}'
