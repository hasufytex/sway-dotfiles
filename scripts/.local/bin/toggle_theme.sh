#!/bin/bash
# Unified dark/light toggle. Flips ~/.config/theme-state, then re-asserts every
# theme-aware tool (i3, kitty, yazi, fzf/bat env, wallpaper, GTK).
#
# Usage:
#   toggle_theme.sh           flip dark<->light and apply
#   toggle_theme.sh --apply   re-apply current state without flipping (used by i3 autostart)
set -u

STATE="$HOME/.config/theme-state"
DOTFILES="$HOME/my-i3-dotfiles"
WALLPAPER_DIR="$HOME/Pictures/wallpapers"

CURRENT=$(cat "$STATE" 2>/dev/null || echo "dark")

if [ "${1:-}" = "--apply" ]; then
    NEW="$CURRENT"
else
    if [ "$CURRENT" = "dark" ]; then NEW="light"; else NEW="dark"; fi
    echo "$NEW" > "$STATE"
fi

# 1. i3 theme symlink
ln -sf "$DOTFILES/i3/.config/i3/theme-${NEW}.conf" \
       "$DOTFILES/i3/.config/i3/theme.conf"

# 2. kitty theme symlink
ln -sf "$DOTFILES/kitty/.config/kitty/theme-${NEW}.conf" \
       "$DOTFILES/kitty/.config/kitty/theme.conf"

# 3. yazi theme symlink
ln -sf "$DOTFILES/yazi/.config/yazi/theme-${NEW}.toml" \
       "$DOTFILES/yazi/.config/yazi/theme.toml"

# 4. fzf + bat env file (sourced by ~/.zshrc; new shells pick it up automatically)
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

# 5. Wallpaper (accept any common extension)
if command -v feh >/dev/null 2>&1; then
    for ext in png jpg jpeg webp; do
        wp="$WALLPAPER_DIR/catppuccin-${NEW}.${ext}"
        if [ -f "$wp" ]; then
            feh --no-fehbg --bg-fill "$wp"
            break
        fi
    done
fi

# 6. GTK — Catppuccin libadwaita/GTK4 + GTK3 overrides
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
/* Catppuccin (${NEW}) — named colors + explicit selectors */
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

/* Explicit overrides — these bypass libadwaita's mode-switching of named colors */
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

# 6b. Claude Code theme (inherits kitty's Catppuccin palette via *-ansi variants)
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
if [ -f "$CLAUDE_SETTINGS" ]; then
    sed -i -E "s/\"theme\": \"(dark|light)(-ansi|-daltonized)?\"/\"theme\": \"${NEW}-ansi\"/" "$CLAUDE_SETTINGS"
fi

# 7. Reload i3 (idempotent)
i3-msg reload >/dev/null 2>&1 || true

# 8. Signal kitty to re-read theme.conf
kill -SIGUSR1 $(pidof kitty) 2>/dev/null || true

# 9. Quit nautilus daemon so the next launch picks up the new gtk.css
if pgrep -x nautilus >/dev/null 2>&1; then
    nautilus -q 2>/dev/null || true
fi

# nvim picks up the change via fs_event watcher on $STATE (see nvim plugins/colorscheme.lua).
# picom is theme-agnostic; not restarted.
