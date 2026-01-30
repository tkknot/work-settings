#!/bin/bash

# Sync nvim settings to ~/.config/nvim

SOURCE_DIR="./nvim"
DEST_DIR="$HOME/.config/nvim"

echo "Syncing $SOURCE_DIR to $DEST_DIR..."

# Ensure destination parent directory exists
mkdir -p "$HOME/.config"

# Sync using rsync
# -a: archive mode
# -v: verbose
# --delete: mirror source exactly
# --exclude='.git': preserve .git directory in destination if it exists
rsync -av --delete --exclude='.git' "$SOURCE_DIR/" "$DEST_DIR/"

echo "Done!"
