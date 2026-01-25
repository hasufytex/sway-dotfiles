#!/bin/bash
# Create folder if it doesn't exist
mkdir -p "$HOME/Pictures/Screenshots"
# Filename with timestamp
FILE="$HOME/Pictures/Screenshots/screenshot_$(date +'%Y-%m-%d_%H-%M-%S').png"
# Take fullscreen screenshot with maim (-u hides cursor)
maim -u "$FILE"
