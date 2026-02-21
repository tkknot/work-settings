#!/bin/bash

# Sync .ai settings first, then create symlinks for .cursor

# Step 1: Sync .ai to ~/.ai
AI_SOURCE_DIR="./.ai"
AI_DEST_DIR="$HOME/.ai"

echo "=== Syncing .ai to $AI_DEST_DIR ==="
mkdir -p "$AI_DEST_DIR"
rsync -av --delete "$AI_SOURCE_DIR/" "$AI_DEST_DIR/"
echo ".ai sync complete!"

# Step 2: Create symlinks in ~/.cursor pointing to ~/.ai
DEST_DIR="$HOME/.cursor"
TARGET_DIRS=("agents" "commands" "rules" "skills")

echo ""
echo "=== Creating symlinks in $DEST_DIR -> $AI_DEST_DIR ==="
mkdir -p "$DEST_DIR"

for dir in "${TARGET_DIRS[@]}"; do
    if [ -d "$AI_DEST_DIR/$dir" ]; then
        # Remove existing directory or symlink
        if [ -e "$DEST_DIR/$dir" ] || [ -L "$DEST_DIR/$dir" ]; then
            echo "Removing existing $DEST_DIR/$dir..."
            rm -rf "$DEST_DIR/$dir"
        fi
        echo "Creating symlink: $DEST_DIR/$dir -> $AI_DEST_DIR/$dir"
        ln -s "$AI_DEST_DIR/$dir" "$DEST_DIR/$dir"
    else
        echo "Warning: $AI_DEST_DIR/$dir not found. Skipping."
    fi
done

# Symlink AGENTS.md
if [ -f "$AI_DEST_DIR/AGENTS.md" ]; then
    rm -f "$DEST_DIR/AGENTS.md"
    echo "Creating symlink: $DEST_DIR/AGENTS.md -> $AI_DEST_DIR/AGENTS.md"
    ln -s "$AI_DEST_DIR/AGENTS.md" "$DEST_DIR/AGENTS.md"
fi

# Symlink mcp.json
if [ -f "$AI_DEST_DIR/mcp.json" ]; then
    rm -f "$DEST_DIR/mcp.json"
    echo "Creating symlink: $DEST_DIR/mcp.json -> $AI_DEST_DIR/mcp.json"
    ln -s "$AI_DEST_DIR/mcp.json" "$DEST_DIR/mcp.json"
fi

# Symlink playwright-config.json
if [ -f "$AI_DEST_DIR/playwright-config.json" ]; then
    rm -f "$DEST_DIR/playwright-config.json"
    echo "Creating symlink: $DEST_DIR/playwright-config.json -> $AI_DEST_DIR/playwright-config.json"
    ln -s "$AI_DEST_DIR/playwright-config.json" "$DEST_DIR/playwright-config.json"
fi

# Symlink .cursorignore
if [ -f "$AI_DEST_DIR/.cursorignore" ]; then
    rm -f "$DEST_DIR/.cursorignore"
    echo "Creating symlink: $DEST_DIR/.cursorignore -> $AI_DEST_DIR/.cursorignore"
    ln -s "$AI_DEST_DIR/.cursorignore" "$DEST_DIR/.cursorignore"
fi

# Symlink .cursorindexignore
if [ -f "$AI_DEST_DIR/.cursorindexignore" ]; then
    rm -f "$DEST_DIR/.cursorindexignore"
    echo "Creating symlink: $DEST_DIR/.cursorindexignore -> $AI_DEST_DIR/.cursorindexignore"
    ln -s "$AI_DEST_DIR/.cursorindexignore" "$DEST_DIR/.cursorindexignore"
fi

echo ""
echo "Cursor sync complete!"
