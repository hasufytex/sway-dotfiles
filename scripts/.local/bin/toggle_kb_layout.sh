#!/bin/bash

# Toggle Layout and write to a file for i3status to read
if setxkbmap -query | grep -q "layout:\s\+us"; then
    setxkbmap -layout bg -variant phonetic
    echo "BG" > /tmp/kb_layout
else
    setxkbmap -layout us -variant ""
    echo "EN" > /tmp/kb_layout
fi

# Refresh i3status immediately
pkill -USR1 i3status
