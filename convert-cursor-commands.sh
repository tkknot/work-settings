#!/usr/bin/env bash
# 目的:
#   カレント配下の .cursor/commands から .md / .mdc を探索し、
#   内容を変更せず拡張子のみ .md に統一して ./.codex/prompts にコピーします。
# 仕様:
#   - 同名（拡張子違い）の競合は .md を優先し、.mdc のコピーはスキップします。
#   - ディレクトリ構造は相対パスを維持します。

set -euo pipefail  # エラー発生時に即終了、未定義変数をエラー扱い、パイプの途中エラーも検知

# 引数（省略時はカレント基準のデフォルト）
SourcePath="${1:-.cursor/commands}"
DestPath="${2:-.codex/prompts}"

# === ディレクトリ存在チェック（cursor / codex） ===
if [ ! -d ".cursor" ]; then
  printf '注意[cursor]: ベースディレクトリが存在しません: %s\n' "./.cursor" >&2
fi

if [ ! -d "$SourcePath" ]; then
  printf 'エラー[cursor]: ソースディレクトリが存在しません: %s\n' "$SourcePath" >&2
  exit 1
fi

if [ ! -d ".codex" ]; then
  printf '情報[codex]: ベースディレクトリが存在しないため作成します: %s\n' "./.codex"
  mkdir -p ./.codex
fi

if [ ! -d "$DestPath" ]; then
  printf '情報[codex/prompts]: 出力先ディレクトリが存在しないため作成します: %s\n' "$DestPath"
  mkdir -p "$DestPath"
else
  printf '情報[codex/prompts]: 出力先ディレクトリ: %s\n' "$DestPath"
fi

# === 処理基準パスの決定 ===
src="$(cd "$SourcePath" && pwd -P)"; src="${src%/}"

echo "処理開始: $src → $DestPath"

copy_one() {
  local file="$1"
  # src からの相対パスを算出
  local rel="${file#"$src/"}"
  # 拡張子を .md に統一
  local target_rel="${rel%.*}.md"
  local out="$DestPath/$target_rel"
  local out_dir
  out_dir="$(dirname "$out")"
  mkdir -p "$out_dir"
  cp -f -- "$file" "$out"
  printf 'コピー: %s -> %s\n' "$file" "$out"
}

# 第1段: .md を先にコピー（md を優先とするため）
while IFS= read -r -d '' f; do
  copy_one "$f"
done < <(find "$src" -type f -iname "*.md" -print0)

# 第2段: .mdc は同名ターゲットがあればスキップ
while IFS= read -r -d '' f; do
  rel="${f#"$src/"}"
  out="$DestPath/${rel%.*}.md"
  if [ -e "$out" ]; then
    printf 'スキップ（mdを優先）: %s\n' "$out"
    continue
  fi
  out_dir="$(dirname "$out")"
  mkdir -p "$out_dir"
  cp -f -- "$f" "$out"
  printf 'コピー: %s -> %s\n' "$f" "$out"
done < <(find "$src" -type f -iname "*.mdc" -print0)

echo "処理完了"
