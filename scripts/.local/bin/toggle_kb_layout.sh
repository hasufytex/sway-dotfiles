#!/bin/bash
# Toggles keyboard layout between US and BG Phonetic for Sway.

# Switch the layout
swaymsg input type:keyboard xkb_switch_layout next >/dev/null

# Update the state file
if swaymsg -t get_inputs | grep -qi '"xkb_active_layout_name": *"Bulgarian'; then
    echo "BG" > /tmp/kb_layout
else
    echo "EN" > /tmp/kb_layout
fi
