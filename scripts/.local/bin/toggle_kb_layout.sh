#!/bin/bash
# Toggles keyboard layout between US and BG Phonetic, writes state to /tmp/kb_layout.
if [ -n "${SWAYSOCK:-}" ]; then
    swaymsg input type:keyboard xkb_switch_layout next >/dev/null
    if swaymsg -t get_inputs | grep -qi '"xkb_active_layout_name": *"Bulgarian'; then
        echo "BG" > /tmp/kb_layout
    else
        echo "EN" > /tmp/kb_layout
    fi
elif setxkbmap -query | grep -q "layout:\s\+us"; then
    setxkbmap -layout bg -variant phonetic
    echo "BG" > /tmp/kb_layout
else
    setxkbmap -layout us -variant ""
    echo "EN" > /tmp/kb_layout
fi
