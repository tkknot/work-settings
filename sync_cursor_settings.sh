#!/bin/bash

# Sync .cursor settings from this directory to ~/.cursor

SOURCE_DIR="./.cursor"
DEST_DIR="$HOME/.cursor"

# List of directories to sync
TARGET_DIRS=("agents" "commands" "rules" "skills")

echo "Starting sync from $SOURCE_DIR to $DEST_DIR..."

for dir in "${TARGET_DIRS[@]}"; do
    if [ -d "$SOURCE_DIR/$dir" ]; then
        echo "Syncing $dir..."
        # Create destination directory if it doesn't exist
        mkdir -p "$DEST_DIR/$dir"
        # Sync using rsync
        # -a: archive mode (preserves permissions, timestamps, etc.)
        # -v: verbose
        # --delete: delete files in destination that are not in source
        rsync -av --delete "$SOURCE_DIR/$dir/" "$DEST_DIR/$dir/"
    else
        echo "Warning: Source directory $SOURCE_DIR/$dir not found. Skipping."
    fi
done

echo "Cursor sync complete!"

# Sync .ai settings
AI_SOURCE_DIR="./.ai"
AI_DEST_DIR="$HOME/.ai"

echo ""
echo "Starting sync from $AI_SOURCE_DIR to $AI_DEST_DIR..."
mkdir -p "$AI_DEST_DIR"
rsync -av --delete "$AI_SOURCE_DIR/" "$AI_DEST_DIR/"
echo ".ai sync complete!"
