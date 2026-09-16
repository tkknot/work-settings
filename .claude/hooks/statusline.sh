#!/usr/bin/env bash
# statusLine 本体。model / effort / context 使用率 / cost / レート制限を1行で出す。
#
# 兼務: 受け取った payload のスナップショットを state ファイルへ書き出す。
# context_window と rate_limits は **statusLine の payload にしか入っていない**（hook イベントは
# 1つも受け取らない）ため、usage-report.sh（Stop）と context-nudge.sh（UserPromptSubmit）は
# ここが書いた state を読む。この2段構えが唯一の経路。
#
# state の置き場所は ~/.claude/ ではなく XDG state ディレクトリ。CLAUDE.md の
# 「状態ファイルと設定ファイルを混在させない」に従う。
#
# stdout はステータス行そのものなので、余計なものを書かないこと。

set -u

input="$(cat)"

# --- jq が無い環境ではモデル名だけ出して終わる（state も書かない） ---
if ! command -v jq >/dev/null 2>&1; then
    printf '%s\n' "$(printf '%s' "$input" | grep -o '"display_name":"[^"]*"' | head -1 | cut -d'"' -f4)"
    exit 0
fi

# --- payload の取り出し。欠落フィールドは空文字になる ---
eval "$(printf '%s' "$input" | jq -r '
  @sh "sid=\(.session_id // "")",
  @sh "model=\(.model.display_name // "")",
  @sh "effort=\(.effort.level // "")",
  @sh "ctx=\(.context_window.used_percentage // "")",
  @sh "cost=\(.cost.total_cost_usd // "")",
  @sh "h5=\(.rate_limits.five_hour.used_percentage // "")",
  @sh "d7=\(.rate_limits.seven_day.used_percentage // "")"
' 2>/dev/null)"

# jq が payload を読めなかった場合（不正 JSON など）は黙って抜ける
[ -n "${model:-}" ] || exit 0

# 小数を整数に丸める（used_percentage は 23.5 のような値で来る）
int_of() { printf '%.0f' "$1" 2>/dev/null || printf ''; }
ctx_i="$([ -n "$ctx" ] && int_of "$ctx")"
h5_i="$([ -n "$h5" ] && int_of "$h5")"
d7_i="$([ -n "$d7" ] && int_of "$d7")"

# --- state ファイルへスナップショットを書く（temp + mv でアトミックに） ---
# statusLine は高頻度で走り、hook が同時に読むため、途中状態を読ませない。
if [ -n "$sid" ]; then
    state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/claude-code"
    state_file="$state_dir/session-${sid}.env"
    if mkdir -p "$state_dir" 2>/dev/null; then
        tmp="$(mktemp "$state_file.XXXXXX" 2>/dev/null)" && {
            {
                printf 'CC_CTX_PCT=%s\n' "${ctx_i:-}"
                printf 'CC_COST_USD=%s\n' "${cost:-}"
                printf 'CC_RL_5H_PCT=%s\n' "${h5_i:-}"
                printf 'CC_RL_7D_PCT=%s\n' "${d7_i:-}"
                printf 'CC_UPDATED_AT=%s\n' "$(date +%s)"
            } >"$tmp" 2>/dev/null && mv -f "$tmp" "$state_file" 2>/dev/null
            rm -f "$tmp" 2>/dev/null
        }
    fi
fi

# --- ステータス行の組み立て ---
YELLOW='\033[33m'; RED='\033[31m'; DIM='\033[2m'; RESET='\033[0m'

line="$model"
[ -n "$effort" ] && line="$line ${DIM}|${RESET} effort: $effort"

if [ -n "$ctx_i" ]; then
    if   [ "$ctx_i" -ge 80 ]; then ctx_fmt="${RED}ctx ${ctx_i}%${RESET}"
    elif [ "$ctx_i" -ge 60 ]; then ctx_fmt="${YELLOW}ctx ${ctx_i}%${RESET}"
    else                           ctx_fmt="ctx ${ctx_i}%"
    fi
    line="$line ${DIM}|${RESET} $ctx_fmt"
fi

[ -n "$cost" ] && line="$line ${DIM}|${RESET} $(printf '$%.2f' "$cost" 2>/dev/null)"

# rate_limits は claude.ai Pro/Max 契約時のみ、かつ初回 API 応答後から入る。
# 来ていない環境では黙って表示から落とす。
[ -n "$h5_i" ] && line="$line ${DIM}|${RESET} 5h ${h5_i}%"
[ -n "$d7_i" ] && line="$line ${DIM}|${RESET} 週 ${d7_i}%"

printf '%b\n' "$line"
