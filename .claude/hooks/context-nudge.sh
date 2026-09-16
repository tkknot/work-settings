#!/usr/bin/env bash
# UserPromptSubmit フック: context 使用率が閾値を超えたら Claude 自身に1度だけ知らせる。
#
# 目的は「早めの compact」。auto compact の閾値を下げる設定は存在しないため、Claude に
# 使用率を伝えて区切りのいいところで /compact を提案させる。
#
# 重要: このスクリプトは stdout に **意図的に** 書く。UserPromptSubmit の plain-text stdout は
# Claude が読むコンテキストとして注入される。それが配送路である一方、毎ターン書くと
# コンテキストが汚染されるため、閾値を跨いだ最初の1回だけに絞っている。
# （常に無音であるべき例は wezterm-tab-status.sh を参照）
#
# 閾値は CC_CONTEXT_NUDGE_PCT で上書きできる（既定 70）。

set -u

input="$(cat)"

command -v jq >/dev/null 2>&1 || exit 0

threshold="${CC_CONTEXT_NUDGE_PCT:-70}"

sid="$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)"
[ -n "$sid" ] || exit 0

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/claude-code"
state_file="$state_dir/session-${sid}.env"
# 通知済みフラグは別ファイル。statusline.sh は .env を丸ごと書き換えるため、
# 同じファイルに持つと毎回フラグが消えて通知が繰り返される。
flag_file="$state_dir/session-${sid}.nudged"

[ -f "$state_file" ] || exit 0

ctx="$(grep -m1 '^CC_CTX_PCT=' "$state_file" 2>/dev/null | cut -d= -f2-)"
[ -n "$ctx" ] || exit 0

# 閾値を下回ったらフラグを落とす。/compact 後に使用率が下がり、再び積み上がったときに
# もう一度通知できるようにするため。落とさないと1セッションで永久に1回しか鳴らない。
if ! [ "$ctx" -ge "$threshold" ] 2>/dev/null; then
    rm -f "$flag_file" 2>/dev/null
    exit 0
fi

# 閾値を超えている間は1回だけ
[ -f "$flag_file" ] && exit 0
: >"$flag_file" 2>/dev/null

cat <<MSG
## context 使用量の通知（UserPromptSubmit hook）

コンテキストウィンドウの使用率が ${ctx}% に達している（閾値 ${threshold}%）。
作業の区切りがついたタイミングで \`/compact\` を提案すること。自動 compact を待つと
会話の途中で走り、文脈が落ちる可能性がある。
MSG

exit 0
