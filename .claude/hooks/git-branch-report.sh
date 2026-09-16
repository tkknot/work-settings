#!/usr/bin/env bash
# SessionStart フック: 現在の git ブランチ状態を Claude のコンテキストに入れる。
#
# 「今どのブランチで作業しているのか」「default ブランチからどれだけ遅れているのか」を
# セッション冒頭で Claude に知らせるのが目的。origin を fetch してから ahead/behind を数える。
#
# 重要: このスクリプトは stdout に **意図的に** 書く。SessionStart の plain-text stdout は
# Claude が読むコンテキストとして注入されるため、それを配送路として使っている。
# （stdout に書いてはいけない例は wezterm-tab-status.sh を参照）
#
# 何があっても exit 0 で抜ける。git 外・remote 無し・ネットワーク不通でセッション開始を
# 止めないため。fetch に失敗した場合はその旨を添えてローカル情報だけ出す。

# フックの JSON は使わないが、読み捨てないと呼び出し側が SIGPIPE になりうる
cat >/dev/null 2>&1

command -v git >/dev/null 2>&1 || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

branch="$(git symbolic-ref --short HEAD 2>/dev/null)"
if [ -z "$branch" ]; then
    # detached HEAD
    branch="(detached at $(git rev-parse --short HEAD 2>/dev/null))"
fi

upstream="$(git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null)"
dirty_count="$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"

echo "## git status (SessionStart hook)"
if [ "$dirty_count" -gt 0 ] 2>/dev/null; then
    echo "- ブランチ: \`$branch\` / upstream: ${upstream:-なし} / 未コミット変更: ${dirty_count} 件"
else
    echo "- ブランチ: \`$branch\` / upstream: ${upstream:-なし} / 作業ツリーはクリーン"
fi

# --- remote が無ければここで終わり ---
git remote get-url origin >/dev/null 2>&1 || {
    echo "- remote \`origin\` が無いため default ブランチとの比較は省略"
    exit 0
}

# --- fetch。失敗しても続行する（オフライン・認証切れ・遅延など） ---
fetch_failed=""
git fetch origin --quiet --no-tags 2>/dev/null || fetch_failed=1

# --- default ブランチの判定 ---
# origin/HEAD があればそれが正。無い場合は main/master の実在で推測する
# （`git remote set-head` は remote refs を書き換えるので、ここでは実行しない）。
default_ref="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null)"
if [ -z "$default_ref" ]; then
    for cand in origin/main origin/master; do
        if git show-ref --verify --quiet "refs/remotes/$cand"; then
            default_ref="$cand"
            break
        fi
    done
fi

if [ -z "$default_ref" ]; then
    echo "- default ブランチを特定できず（origin/HEAD も origin/main|master も無し）"
    [ -n "$fetch_failed" ] && echo "- 注意: \`git fetch origin\` が失敗したため remote 情報は古い可能性がある"
    exit 0
fi

# --- ahead / behind ---
counts="$(git rev-list --left-right --count "$default_ref...HEAD" 2>/dev/null)"
behind="$(printf '%s' "$counts" | cut -f1)"
ahead="$(printf '%s' "$counts" | cut -f2)"

if [ -z "$counts" ]; then
    echo "- \`$default_ref\` との差分を計算できなかった"
elif [ "$default_ref" = "origin/${branch}" ]; then
    echo "- default ブランチ \`$default_ref\` 上で作業中（ahead ${ahead} / behind ${behind}）"
else
    echo "- default \`$default_ref\` に対して ahead ${ahead} / behind ${behind}"
    if [ "${behind:-0}" -gt 0 ] 2>/dev/null; then
        echo "- default ブランチに ${behind} 件の変更が入っている。必要なら取り込みを提案すること"
    fi
fi

[ -n "$fetch_failed" ] && echo "- 注意: \`git fetch origin\` が失敗したため上記の remote 情報は古い可能性がある"

exit 0
