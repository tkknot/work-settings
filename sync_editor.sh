#!/bin/bash

# エディタ系設定（nvim / wezterm）をホームディレクトリに配布する
# - nvim    -> ~/.config/nvim
# - wezterm -> ~/.config/wezterm （WSL の場合は Windows 側にも配布）

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ------------------------------------------------------------------
# nvim
# ------------------------------------------------------------------
NVIM_SOURCE_DIR="$SCRIPT_DIR/nvim"
NVIM_DEST_DIR="$HOME/.config/nvim"

echo "Syncing $NVIM_SOURCE_DIR to $NVIM_DEST_DIR..."

# Ensure destination parent directory exists
mkdir -p "$HOME/.config"

# Sync using rsync
# -a: archive mode
# -v: verbose
# --delete: mirror source exactly
# --exclude='.git': preserve .git directory in destination if it exists
rsync -av --delete --exclude='.git' "$NVIM_SOURCE_DIR/" "$NVIM_DEST_DIR/"

# ------------------------------------------------------------------
# wezterm
# ------------------------------------------------------------------
WEZTERM_SOURCE_DIR="$SCRIPT_DIR/wezterm"
WEZTERM_DEST_DIR="$HOME/.config/wezterm"

echo ""
echo "Syncing $WEZTERM_SOURCE_DIR to $WEZTERM_DEST_DIR..."

rsync -av --delete --exclude='.git' "$WEZTERM_SOURCE_DIR/" "$WEZTERM_DEST_DIR/"

# Check if running in WSL
if [ -f /proc/version ] && grep -qi Microsoft /proc/version; then
  WINDOWS_USER="taked"
  WINDOWS_DEST_DIR="/mnt/c/Users/$WINDOWS_USER/.config/wezterm"

  echo "WSL detected. Syncing to Windows path: $WINDOWS_DEST_DIR..."

  # Ensure Windows destination parent directory exists
  mkdir -p "/mnt/c/Users/$WINDOWS_USER/.config"

  rsync -av --delete --exclude='.git' "$WEZTERM_SOURCE_DIR/" "$WINDOWS_DEST_DIR/"

  # Also copy to %USERPROFILE%\.wezterm.lua for maximum compatibility
  cp "$WEZTERM_SOURCE_DIR/wezterm.lua" "/mnt/c/Users/$WINDOWS_USER/.wezterm.lua"
  echo "Synced to /mnt/c/Users/$WINDOWS_USER/.wezterm.lua"
fi

echo ""
echo "Done!"
