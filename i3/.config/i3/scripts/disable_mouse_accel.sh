#!/bin/bash
# Apply flat acceleration profile to all pointer devices
xinput list --id-only | while read id; do
    if xinput list-props "$id" 2>/dev/null | grep -q "libinput Accel Profile Enabled"; then
        xinput set-prop "$id" "libinput Accel Profile Enabled" 0 1
    fi
done
