#!/bin/bash
# Create folder if it doesn't exist
mkdir -p "$HOME/Pictures/Screenshots"
# Filename with timestamp
FILE="$HOME/Pictures/Screenshots/screenshot_$(date +'%Y-%m-%d_%H-%M-%S').png"
# Take screenshot with maim and save (-u hides cursor)
maim -u -s "$FILE"
