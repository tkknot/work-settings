#!/usr/bin/env bash
# SessionStart フック: statusline.sh が書いた state ファイルの古いものを掃除する。
#
# state はセッションごとに 1 ファイル（session-<id>.env と session-<id>.nudged）増える。
# statusLine は高頻度で走るためそこで掃除するのは無駄が多く、セッション開始時に一度だけ行う。
#
# 重要: stdout には何も書かない。SessionStart の plain-text stdout は Claude が読む
# コンテキストとして注入されるため、掃除の報告が混入するとコンテキストを汚す。

cat >/dev/null 2>&1

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/claude-code"
[ -d "$state_dir" ] || exit 0

# 7 日以上更新のないものを削除。-maxdepth 1 でサブディレクトリには触れない
find "$state_dir" -maxdepth 1 -type f \
     \( -name 'session-*.env' -o -name 'session-*.nudged' -o -name 'session-*.env.*' \) \
     -mtime +7 -delete 2>/dev/null

exit 0
