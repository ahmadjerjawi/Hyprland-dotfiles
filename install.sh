#!/bin/bash

set -e

CONFIG_DIRS=("alacritty" "hypr" "rofi" "waybar")
SOURCE_DIR="$(pwd)/.config"
DEST_DIR="$HOME/.config"
TIMESTAMP=$(date +"%Y-%m-%d-%H%M%S")

echo "🚀 Starting dotfiles installation..."

for DIR in "${CONFIG_DIRS[@]}"; do
    SRC="$SOURCE_DIR/$DIR"
    DEST="$DEST_DIR/$DIR"

    echo -e "\n📁 Processing: $DIR"

    # Check if current config exists and back it up
    if [ -d "$DEST" ]; then
        BACKUP_DIR="${DEST_DIR}/${DIR}-backup-${TIMESTAMP}"
        echo "🗃️  Backing up existing $DEST to $BACKUP_DIR"
        mv "$DEST" "$BACKUP_DIR"
    fi

    # Copy new config
    if [ -d "$SRC" ]; then
        echo "📥 Installing $DIR from $SRC to $DEST"
        cp -r "$SRC" "$DEST"
    else
        echo "⚠️  Skipping $DIR — source not found at $SRC"
    fi
done

echo -e "\n✅ Installation complete!"
