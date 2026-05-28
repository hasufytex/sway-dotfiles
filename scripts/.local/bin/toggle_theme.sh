#!/bin/bash
STATE="$HOME/.config/theme-state"
CURRENT=$(cat "$STATE" 2>/dev/null || echo "dark")

if [ "$CURRENT" = "dark" ]; then
    NEW="light"
else
    NEW="dark"
fi

echo "$NEW" > "$STATE"

ln -sf "$HOME/my-i3-dotfiles/i3/.config/i3/theme-${NEW}.conf" \
       "$HOME/my-i3-dotfiles/i3/.config/i3/theme.conf"

ln -sf "$HOME/my-i3-dotfiles/kitty/.config/kitty/theme-${NEW}.conf" \
       "$HOME/my-i3-dotfiles/kitty/.config/kitty/theme.conf"

gsettings set org.gnome.desktop.interface color-scheme "prefer-${NEW}"

i3-msg reload

kill -SIGUSR1 $(pidof kitty) 2>/dev/null || true
