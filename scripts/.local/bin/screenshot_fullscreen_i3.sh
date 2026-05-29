#!/bin/bash
# Capture fullscreen and save to ~/Pictures/Screenshots.
mkdir -p "$HOME/Pictures/Screenshots"
FILE="$HOME/Pictures/Screenshots/screenshot_$(date +'%Y-%m-%d_%H-%M-%S').png"
maim -u "$FILE"
