#!/bin/bash

# Sync .claude settings from this directory to ~/.claude

SOURCE_DIR="./.claude"
DEST_DIR="$HOME/.claude"

# List of directories to sync
TARGET_DIRS=("agents" "commands" "rules" "skills")

echo "Starting sync from $SOURCE_DIR to $DEST_DIR..."

for dir in "${TARGET_DIRS[@]}"; do
    if [ -d "$SOURCE_DIR/$dir" ]; then
        echo "Syncing $dir..."
        mkdir -p "$DEST_DIR/$dir"
        rsync -av --delete "$SOURCE_DIR/$dir/" "$DEST_DIR/$dir/"
    else
        echo "Warning: Source directory $SOURCE_DIR/$dir not found. Skipping."
    fi
done

# Sync CLAUDE.md
if [ -f "$SOURCE_DIR/CLAUDE.md" ]; then
    echo "Syncing CLAUDE.md..."
    cp "$SOURCE_DIR/CLAUDE.md" "$DEST_DIR/CLAUDE.md"
fi

echo "Sync complete!"
