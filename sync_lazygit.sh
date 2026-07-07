#!/bin/bash

# lazygit 設定をホームディレクトリに配布する
# - lazygit -> ~/.config/lazygit

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

LAZYGIT_SOURCE_DIR="$SCRIPT_DIR/lazygit"
LAZYGIT_DEST_DIR="$HOME/.config/lazygit"

echo "Syncing $LAZYGIT_SOURCE_DIR to $LAZYGIT_DEST_DIR..."

# Ensure destination parent directory exists
mkdir -p "$HOME/.config"

rsync -av --delete --exclude='.git' "$LAZYGIT_SOURCE_DIR/" "$LAZYGIT_DEST_DIR/"

# diff preview の行番号表示にはページャーとして delta (git-delta) が必要
if ! command -v delta >/dev/null 2>&1; then
  echo ""
  echo "WARNING: delta (git-delta) が見つかりません。"
  echo "  lazygit の diff preview はエラーになります。以下のいずれかでインストールしてください:"
  echo "    cargo install git-delta"
  echo "    sudo apt install git-delta"
  echo "    brew install git-delta"
fi

echo ""
echo "Done!"
