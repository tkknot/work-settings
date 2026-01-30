#!/bin/bash

# Sync .gemini settings from this directory to ~/.gemini

SOURCE_DIR="./.gemini"
DEST_DIR="$HOME/.gemini"

# List of directories to sync
TARGET_DIRS=("agents" "commands" "skills")

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

# Sync AGENTS.md
if [ -f "$SOURCE_DIR/AGENTS.md" ]; then
    echo "Syncing AGENTS.md..."
    cp "$SOURCE_DIR/AGENTS.md" "$DEST_DIR/AGENTS.md"
fi

# Sync settings.json
if [ -f "$SOURCE_DIR/settings.json" ]; then
    echo "Syncing settings.json..."
    cp "$SOURCE_DIR/settings.json" "$DEST_DIR/settings.json"
fi

echo "Sync complete!"
