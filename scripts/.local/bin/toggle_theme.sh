#!/bin/bash
# Dark/light theme toggle: sway, eww, kitty, yazi, GTK, fzf/bat, Claude Code.
# Usage: toggle_theme.sh [--apply]  (--apply re-applies without flipping)
set -u

STATE="$HOME/.config/theme-state"
DOTFILES="$HOME/my-i3-dotfiles"
WALLPAPER="$HOME/Downloads/1378545.jpg"

CURRENT=$(cat "$STATE" 2>/dev/null || echo "dark")

if [ "${1:-}" = "--apply" ]; then
    APPLY=1
    NEW="$CURRENT"
else
    APPLY=0
    if [ "$CURRENT" = "dark" ]; then NEW="light"; else NEW="dark"; fi
    echo "$NEW" > "$STATE"
fi

ln -sf "$DOTFILES/sway/.config/sway/theme-${NEW}.conf" \
       "$DOTFILES/sway/.config/sway/theme.conf"

ln -sf "$HOME/.config/eww/theme-${NEW}.scss" \
       "$HOME/.config/eww/eww.scss"
if [ "$APPLY" -eq 0 ]; then
    ~/.local/bin/eww-bar &
fi

ln -sf "$DOTFILES/kitty/.config/kitty/theme-${NEW}.conf" \
       "$DOTFILES/kitty/.config/kitty/theme.conf"

ln -sf "$DOTFILES/yazi/.config/yazi/theme-${NEW}.toml" \
       "$DOTFILES/yazi/.config/yazi/theme.toml"

if [ "$NEW" = "dark" ]; then
    cat > "$HOME/.config/theme-colors.sh" <<'EOF'
export BAT_THEME="Catppuccin Mocha"
export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8 \
--color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
--color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
--color=selected-bg:#45475A \
--color=border:#6C7086,label:#CDD6F4"
EOF
else
    cat > "$HOME/.config/theme-colors.sh" <<'EOF'
export BAT_THEME="Catppuccin Latte"
export FZF_DEFAULT_OPTS=" \
--color=bg+:#CCD0DA,bg:#EFF1F5,spinner:#DC8A78,hl:#D20F39 \
--color=fg:#4C4F69,header:#D20F39,info:#8839EF,pointer:#DC8A78 \
--color=marker:#7287FD,fg+:#4C4F69,prompt:#8839EF,hl+:#D20F39 \
--color=selected-bg:#BCC0CC \
--color=border:#9CA0B0,label:#4C4F69"
EOF
fi

if [ -f "$WALLPAPER" ]; then
    swaymsg output "*" bg "$WALLPAPER" fill >/dev/null 2>&1 || true
fi

mkdir -p "$HOME/.config/gtk-4.0" "$HOME/.config/gtk-3.0"
if [ "$NEW" = "dark" ]; then
    BASE="#1e1e2e"; MANTLE="#181825"; CRUST="#11111b"
    TEXT="#cdd6f4"; SUBTEXT="#a6adc8"
    SURF0="#313244"; SURF1="#45475a"
    ACCENT="#89b4fa"; ACCENT_FG="#1e1e2e"
    DESTRUCT="#f38ba8"; SUCCESS="#a6e3a1"; WARN="#f9e2af"
else
    BASE="#eff1f5"; MANTLE="#e6e9ef"; CRUST="#dce0e8"
    TEXT="#4c4f69"; SUBTEXT="#6c6f85"
    SURF0="#ccd0da"; SURF1="#bcc0cc"
    ACCENT="#1e66f5"; ACCENT_FG="#eff1f5"
    DESTRUCT="#d20f39"; SUCCESS="#40a02b"; WARN="#df8e1d"
fi
cat > "$HOME/.config/gtk-4.0/gtk.css" <<EOF
@define-color accent_color             ${ACCENT};
@define-color accent_bg_color          ${ACCENT};
@define-color accent_fg_color          ${ACCENT_FG};
@define-color destructive_color        ${DESTRUCT};
@define-color destructive_bg_color     ${DESTRUCT};
@define-color destructive_fg_color     ${ACCENT_FG};
@define-color success_color            ${SUCCESS};
@define-color warning_color            ${WARN};
@define-color error_color              ${DESTRUCT};
@define-color window_bg_color          ${BASE};
@define-color window_fg_color          ${TEXT};
@define-color view_bg_color            ${MANTLE};
@define-color view_fg_color            ${TEXT};
@define-color headerbar_bg_color       ${CRUST};
@define-color headerbar_fg_color       ${TEXT};
@define-color headerbar_border_color   ${CRUST};
@define-color headerbar_backdrop_color ${MANTLE};
@define-color sidebar_bg_color         ${MANTLE};
@define-color sidebar_fg_color         ${TEXT};
@define-color sidebar_backdrop_color   ${CRUST};
@define-color sidebar_border_color     ${SURF0};
@define-color card_bg_color            ${SURF0};
@define-color card_fg_color            ${TEXT};
@define-color dialog_bg_color          ${BASE};
@define-color dialog_fg_color          ${TEXT};
@define-color popover_bg_color         ${MANTLE};
@define-color popover_fg_color         ${TEXT};
@define-color thumbnail_bg_color       ${SURF0};
@define-color thumbnail_fg_color       ${TEXT};

window, .background { background-color: ${BASE}; color: ${TEXT}; }
headerbar, .titlebar { background-color: ${CRUST}; color: ${TEXT}; }
.sidebar, placessidebar, placessidebar list { background-color: ${MANTLE}; color: ${TEXT}; }
.sidebar row:selected, placessidebar row:selected { background-color: ${SURF0}; color: ${TEXT}; }
popover > contents, menu, .menu, .context-menu { background-color: ${MANTLE}; color: ${TEXT}; }
.view, textview, treeview, listview, gridview { background-color: ${MANTLE}; color: ${TEXT}; }
entry, .entry { background-color: ${SURF0}; color: ${TEXT}; }
button { color: ${TEXT}; }
EOF
cp "$HOME/.config/gtk-4.0/gtk.css" "$HOME/.config/gtk-3.0/gtk.css"

gsettings set org.gnome.desktop.interface color-scheme "prefer-${NEW}" 2>/dev/null || true
if [ "$NEW" = "dark" ]; then
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' 2>/dev/null || true
else
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita' 2>/dev/null || true
fi

CLAUDE_SETTINGS="$HOME/.claude/settings.json"
if [ -f "$CLAUDE_SETTINGS" ]; then
    sed -i -E "s/\"theme\": \"(dark|light)(-ansi|-daltonized)?\"/\"theme\": \"${NEW}-ansi\"/" "$CLAUDE_SETTINGS"
fi

if [ "$APPLY" -eq 0 ]; then
    swaymsg reload >/dev/null 2>&1 || true
fi

kill -SIGUSR1 $(pidof kitty) 2>/dev/null || true

if [ "$APPLY" -eq 0 ] && pgrep -x nautilus >/dev/null 2>&1; then
    nautilus -q 2>/dev/null || true
fi
