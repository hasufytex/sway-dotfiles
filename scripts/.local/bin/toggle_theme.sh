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

FLAVOR=$([ "$NEW" = dark ] && echo mocha || echo latte)
source "$DOTFILES/scripts/.local/bin/catppuccin-palette.sh"
load_palette "$FLAVOR"
RENDER_VARS=$(printf '${%s} ' "${CATPPUCCIN_NAMES[@]}")
render() { envsubst "$RENDER_VARS" < "$1" > "$2"; }

ln -sf "$DOTFILES/sway/.config/sway/theme-${NEW}.conf" \
       "$DOTFILES/sway/.config/sway/theme.conf"

render "$HOME/.config/eww/eww.scss.in" "$HOME/.config/eww/eww.scss"
if [ "$APPLY" -eq 0 ]; then
    ~/.local/bin/eww-bar &
fi

render "$DOTFILES/kitty/.config/kitty/theme-${NEW}.conf.in" \
       "$DOTFILES/kitty/.config/kitty/theme.conf"

render "$DOTFILES/yazi/.config/yazi/theme-${NEW}.toml.in" \
       "$DOTFILES/yazi/.config/yazi/theme.toml"

cat > "$HOME/.config/theme-colors.sh" <<EOF
export BAT_THEME="Catppuccin ${FLAVOR^}"
export FZF_DEFAULT_OPTS="--color=bg+:${surface0},bg:${base},spinner:${rosewater},hl:${red},fg:${text},header:${red},info:${mauve},pointer:${rosewater},marker:${lavender},fg+:${text},prompt:${mauve},hl+:${red},selected-bg:${surface1},border:${overlay0},label:${text}"
export PROMPT_HEX="${accent}"
export PS1_COLOR=\$'\\e[38;2;$(hex2rgb "$accent")m'
EOF

if [ -f "$WALLPAPER" ]; then
    swaymsg output "*" bg "$WALLPAPER" fill >/dev/null 2>&1 || true
fi

mkdir -p "$HOME/.config/gtk-4.0" "$HOME/.config/gtk-3.0"
BASE=$base; MANTLE=$mantle; CRUST=$crust
TEXT=$text; SUBTEXT=$subtext0
SURF0=$surface0; SURF1=$surface1
ACCENT=$accent; ACCENT_FG=$accent_fg
DESTRUCT=$red; SUCCESS=$green; WARN=$yellow
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
    gsettings set org.gnome.desktop.interface gtk-theme 'catppuccin-mocha-mauve-standard+default' 2>/dev/null || true
else
    gsettings set org.gnome.desktop.interface gtk-theme 'catppuccin-latte-mauve-standard+default' 2>/dev/null || true
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
