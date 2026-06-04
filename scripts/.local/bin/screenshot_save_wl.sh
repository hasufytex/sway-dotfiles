#!/bin/bash
# Capture selected area and save to ~/Pictures/Screenshots.
mkdir -p "$HOME/Pictures/Screenshots"
FILE="$HOME/Pictures/Screenshots/screenshot_$(date +'%Y-%m-%d_%H-%M-%S').png"
grim -g "$(slurp)" "$FILE"
