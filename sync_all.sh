#!/bin/bash

# すべての sync_*.sh スクリプトを一括実行する
#
# このスクリプトと同じディレクトリにある sync_*.sh を自動で検出し、
# 順番に `bash` で実行する。各スクリプトの成否を最後にまとめて表示する。
# スクリプトが増減しても自動で対象に含まれる（自分自身は除外）。

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SELF="$(basename "${BASH_SOURCE[0]}")"

# --- 実行対象の sync_*.sh を収集（自分自身は除外）---
scripts=()
for f in "$SCRIPT_DIR"/sync_*.sh; do
	[ -e "$f" ] || continue
	name="$(basename "$f")"
	[ "$name" = "$SELF" ] && continue
	scripts+=("$f")
done

if [ ${#scripts[@]} -eq 0 ]; then
	echo "実行対象の sync_*.sh が見つかりませんでした。"
	exit 0
fi

echo "=== ${#scripts[@]} 個の sync スクリプトを実行します ==="
echo

# --- 順番に実行し、成否を記録する ---
results=()
failed=0

for f in "${scripts[@]}"; do
	name="$(basename "$f")"
	echo "----- ▶ $name -----"
	if bash "$f"; then
		results+=("✅ $name")
	else
		code=$?
		results+=("❌ $name (exit $code)")
		failed=1
	fi
	echo
done

# --- 実行結果のサマリ ---
echo "=== 実行結果 ==="
for r in "${results[@]}"; do
	echo "  $r"
done

exit $failed
