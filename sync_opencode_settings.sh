#!/bin/bash

# Sync opencode settings to ~/.config/opencode

SOURCE_DIR="./opencode"
DEST_DIR="$HOME/.config/opencode"

echo "Syncing $SOURCE_DIR to $DEST_DIR..."

# Ensure destination parent directory exists
mkdir -p "$HOME/.config"

# Simple sync using rsync
# -a: archive mode
# -v: verbose
# --delete: mirror source exactly (removes files in dest not in source)
rsync -av --delete "$SOURCE_DIR/" "$DEST_DIR/"

echo "Done!"
