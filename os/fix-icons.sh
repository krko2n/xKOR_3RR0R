#!/bin/bash
# Convert icons to RGBA format for Tauri
# Requires ImageMagick (convert command)

set -e

ICON_DIR="src-tauri/icons"

echo "Converting icons to RGBA format..."

for icon in "$ICON_DIR"/*.png; do
    if [ -f "$icon" ]; then
        echo "Converting: $icon"
        # Convert to RGBA (add alpha channel if missing)
        convert "$icon" -alpha on "$icon.tmp" && mv "$icon.tmp" "$icon"
    fi
done

echo "Icon conversion complete."
