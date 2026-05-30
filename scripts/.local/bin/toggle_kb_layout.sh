#!/bin/bash
# Toggles keyboard layout between US and BG Phonetic, writes state to /tmp/kb_layout.
if setxkbmap -query | grep -q "layout:\s\+us"; then
    setxkbmap -layout bg -variant phonetic
    echo "BG" > /tmp/kb_layout
else
    setxkbmap -layout us -variant ""
    echo "EN" > /tmp/kb_layout
fi
