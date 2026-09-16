#!/usr/bin/env bash
# Claude Code の実行状態を WezTerm のタブ名にアイコンで出すためのフック。
#
# OSC 1337 SetUserVar=claude_tab_status=<状態> を pty へ書き、
# wezterm.lua の format-tab-title がそれを読んでタブ名の先頭にアイコンを前置する。
# 同じ方式の前例は shell/wezterm-nvim.sh の claude_open_nvim。
#
#   使い方: wezterm-tab-status.sh <run|wait|done|idle>
#
# 重要: stdout には絶対に何も書かない。UserPromptSubmit フックの plain-text stdout は
# Claude が読むコンテキストとして注入されるため、混入すると毎ターン汚染される。
# PostToolUse は毎ツール呼び出しで発火するので特に影響が大きい。
#
# 重要: Claude Code はフックを制御端末なしで起動するため、/dev/tty への書き込みは
# 「device not configured」で失敗する。そのため /dev/tty が失敗したときだけ、
# $PPID から親プロセスを辿って pane の実 tty デバイスへ直接書くフォールバックを持つ。

# フックの JSON は使わないが、読み捨てないと呼び出し側が SIGPIPE になりうる
cat >/dev/null 2>&1

status="${1:-idle}"

# WezTerm 以外では何もしない（WSL でも TERM_PROGRAM は伝播する。shell/wezterm-nvim.sh と同じ判定）
[ "${TERM_PROGRAM:-}" = "WezTerm" ] || exit 0
command -v base64 >/dev/null 2>&1 || exit 0

# base64 は環境により折り返すため tr で改行を落とす。終端は wezterm-nvim.sh に合わせて BEL
b64="$(printf '%s' "$status" | base64 | tr -d '\n')"

# 指定デバイスへ OSC を書く。書けなければ（存在しない・権限がない・制御端末が無い）
# エラーごと捨てて非 0 を返す。stdout には何も出さない。
#
# -c でキャラクタデバイスであることを必ず確認する。`>` は存在しないパスを
# 通常ファイルとして作ってしまうため、これが無いと存在しない端末名でも「成功」に
# 見えてしまい、/dev 配下にゴミファイルを作った上でフォールバックの続行を止める。
emit_osc() {
    [ -c "$1" ] || return 1
    { printf '\033]1337;SetUserVar=claude_tab_status=%s\007' "$b64" >"$1"; } 2>/dev/null
}

# 1) 従来どおりまず制御端末へ。成功すればここで終わり（既存の正常な環境の挙動を変えない）
emit_osc /dev/tty && exit 0

# 2) 制御端末が無い場合のフォールバック。
#    親プロセスを最大 8 段辿り、端末を持つ祖先（claude → zsh → …）の tty デバイスへ直接書く。
#    macOS は ttysNNN、Linux/WSL は pts/N。端末を持たないプロセスは ? / ?? になるのでスキップ。
#    ps はすべてコマンド置換で受け、stderr も捨てて stdout を汚さないこと。
command -v ps >/dev/null 2>&1 || exit 0

pid="$PPID"
i=0
while [ "$i" -lt 8 ]; do
    i=$((i + 1))

    # ps は右寄せパディングを付けるため前後の空白を落とす（例: "  165"）
    tty_name="$(ps -o tty= -p "$pid" 2>/dev/null | tr -d '[:space:]')"

    case "$tty_name" in
        # macOS: ttys009 / Linux: tty1 / Linux(WSL): pts/0
        ttys[0-9]* | pts/[0-9]* | tty[0-9]*)
            # マッチしても書けないことがある（権限など）。その場合は打ち切らず親へ進む
            emit_osc "/dev/$tty_name" && exit 0
            ;;
    esac

    ppid="$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d '[:space:]')"
    case "$ppid" in
        '' | 0 | 1) break ;;   # 辿れない / init まで来たら打ち切り
        *[!0-9]*) break ;;     # 数値以外が返ったら打ち切り
    esac
    pid="$ppid"
done

# 端末が見つからなくても静かに成功で終わる（フックがエラーを出さないこと自体が要件）
exit 0
