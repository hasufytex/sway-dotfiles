!/bin/bash

# 1. Toggle Keyboard Layout
# Since i3 uses X11, we use setxkbmap. 
# This command toggles between US and your secondary layout (e.g., Bulgarian/German/etc.)
if setxkbmap -query | grep -q "layout:\s\+us"; then
    setxkbmap bg  # Replace 'bg' with your other language code
else
    setxkbmap us
fi

# 2. Refresh the Bar
# If you are using i3status:
pkill -USR1 i3status