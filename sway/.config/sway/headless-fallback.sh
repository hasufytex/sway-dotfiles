#!/bin/sh
# Keep exactly one display for Sunshine to stream: the virtual HEADLESS-1
# output is enabled only while the real monitor (DP-3) is unplugged, switched
# off or disabled, so Sunshine always captures whichever screen is in use.

REAL=DP-3
VIRT=HEADLESS-1

active() {
    swaymsg -t get_outputs -r |
        jq -e --arg n "$1" 'any(.[]; .name == $n and .active)' >/dev/null
}

update() {
    if active "$REAL"; then
        active "$VIRT" && swaymsg -q "output $VIRT disable"
    else
        active "$VIRT" || swaymsg -q "output $VIRT enable"
    fi
}

# Create the virtual output once per sway session.
swaymsg -t get_outputs -r | jq -e --arg n "$VIRT" 'any(.[]; .name == $n)' >/dev/null ||
    swaymsg -q create_output

update
swaymsg -t subscribe -m '["output"]' | while read -r _; do update; done
