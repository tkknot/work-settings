#!/bin/bash

# Sync wezterm settings to ~/.config/wezterm

SOURCE_DIR="./wezterm"
DEST_DIR="$HOME/.config/wezterm"

echo "Syncing $SOURCE_DIR to $DEST_DIR..."

# Ensure destination parent directory exists
mkdir -p "$HOME/.config"

# Sync using rsync
rsync -av --delete --exclude='.git' "$SOURCE_DIR/" "$DEST_DIR/"

# Check if running in WSL
if [ -f /proc/version ] && grep -qi Microsoft /proc/version; then
  WINDOWS_USER="taked"
  WINDOWS_DEST_DIR="/mnt/c/Users/$WINDOWS_USER/.config/wezterm"
  
  echo "WSL detected. Syncing to Windows path: $WINDOWS_DEST_DIR..."
  
  # Ensure Windows destination parent directory exists
  mkdir -p "/mnt/c/Users/$WINDOWS_USER/.config"
  
  rsync -av --delete --exclude='.git' "$SOURCE_DIR/" "$WINDOWS_DEST_DIR/"
fi

echo "Done!"
