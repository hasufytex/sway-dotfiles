#!/bin/bash
# Capture selected area, save to ~/Pictures/Screenshots, and copy to clipboard.
set -e

GEOMETRY=$(slurp) || exit 0
[ -n "$GEOMETRY" ] || exit 0

mkdir -p "$HOME/Pictures/Screenshots"
FILE="$HOME/Pictures/Screenshots/screenshot_$(date +'%Y-%m-%d_%H-%M-%S').png"
grim -g "$GEOMETRY" "$FILE"
wl-copy -t image/png < "$FILE"
