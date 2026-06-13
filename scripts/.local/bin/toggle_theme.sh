#!/bin/bash
# Dark/light theme toggle: sway, kitty, yazi, GTK, fzf/bat, Claude Code.
# Usage: toggle_theme.sh [--apply]  (--apply re-applies without flipping)
set -u

# ==============================================================================
# USER CONFIGURATION: CHANGE VISUAL PREFERENCES HERE
# ==============================================================================
# All Available Dark Flavors:
#   latte, frappe, macchiato, mocha
DARK_FLAVOR="mocha"

# All Available Accent Options:
#   rosewater, flamingo, pink, mauve, red, maroon, peach, yellow, green,
#   teal, sky, sapphire, blue, lavender, text, subtext1, subtext0, overlay2,
#   overlay1, overlay0, surface2, surface1, surface0, base, mantle, crust
ACCENT_CHOICE="blue"
# ==============================================================================

STATE="$HOME/.config/theme-state"
DOTFILES="$HOME/sway-dotfiles"
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

# Assign the flavor based on your preferences
FLAVOR=$([ "$NEW" = dark ] && echo "$DARK_FLAVOR" || echo "latte")

source "$DOTFILES/scripts/.local/bin/catppuccin-palette.sh"
load_palette "$FLAVOR"

# Overwrite the accent to follow your top-level ACCENT_CHOICE variable
eval "accent=\$$ACCENT_CHOICE"


# Define the render function first
render() { envsubst "$RENDER_VARS" < "$1" > "$2"; }

# 1. Update RENDER_VARS to include both accent and accent_fg
RENDER_VARS=$(printf '${%s} ' "${CATPPUCCIN_NAMES[@]}")
RENDER_VARS="$RENDER_VARS \${accent} \${accent_fg}"

# 2. Render Sway
render "$DOTFILES/sway/.config/sway/theme-${NEW}.conf.in" "$DOTFILES/sway/.config/sway/theme.conf"

# Custom C bar: template installed by `make install` in the bar repo; the
# running bar reloads the rendered file on mtime change, no restart needed
if [ -f "$HOME/.local/share/bar/theme.conf.in" ]; then
    mkdir -p "$HOME/.config/bar"
    render "$HOME/.local/share/bar/theme.conf.in" "$HOME/.config/bar/theme.conf"
fi

# 3. Render the updated Kitty theme template
render "$DOTFILES/kitty/.config/kitty/theme-${NEW}.conf.in" \
       "$DOTFILES/kitty/.config/kitty/theme.conf"

# 4. Force Kitty to live-reload the new colors instantly
if command -v kitty >/dev/null 2>&1; then
    kitty @ set-colors --all "$DOTFILES/kitty/.config/kitty/theme.conf" 2>/dev/null || true
fi

render "$DOTFILES/yazi/.config/yazi/theme-${NEW}.toml.in" \
       "$DOTFILES/yazi/.config/yazi/theme.toml"

cat > "$HOME/.config/theme-colors.sh" <<EOF
export BAT_THEME="Catppuccin ${FLAVOR^}"
export FZF_DEFAULT_OPTS="--color=bg+:${surface0},bg:${base},spinner:${rosewater},hl:${red},fg:${text},header:${red},info:${mauve},pointer:${rosewater},marker:${lavender},fg+:${text},prompt:${mauve},hl+:${red},selected-bg:${surface1},border:${overlay0},label:${text}"
export PROMPT_HEX="${accent}"
export PS1_COLOR=\$'\\e[38;2;$(hex2rgb "$accent")m'
EOF

# Lock-screen colours for swaylock_themed. swaylock wants bare RRGGBB(AA), so
# strip the leading '#'. RING follows the accent, like every other app.
sl_base=${base#\#}; sl_accent=${accent#\#}; sl_mauve=${mauve#\#}
sl_red=${red#\#}; sl_green=${green#\#}; sl_yellow=${yellow#\#}; sl_text=${text#\#}
cat > "$HOME/.config/swaylock-colors.sh" <<EOF
FALLBACK="${sl_base}"
INSIDE="${sl_base}cc"
RING="${sl_accent}"
KEYHL="${sl_mauve}"
BSHL="${sl_red}"
RINGVER="${sl_green}"
RINGWRONG="${sl_red}"
RINGCLEAR="${sl_yellow}"
TEXT="${sl_text}"
TEXTVER="${sl_green}"
TEXTWRONG="${sl_red}"
TEXTCLEAR="${sl_yellow}"
CAPS="${sl_yellow}"
EOF

# Vesktop (Discord): import the matching catppuccin flavor/accent. The dist
# ships every catppuccin-<flavor>-<accent> combo, so this tracks DARK_FLAVOR /
# ACCENT_CHOICE automatically and the imported base matches the bar/terminal.
# Vesktop live-reloads quickCss on mtime change, so no restart is needed. Only
# the marked block is managed; any custom QuickCSS below it is preserved.
VESKTOP_CSS="$HOME/.config/vesktop/settings/quickCss.css"
if [ -d "${VESKTOP_CSS%/*}" ]; then
    # Drop the previous managed block and any stale discord import, keeping the
    # user's own CSS; the @import must stay first, so the managed block leads.
    REST=""
    [ -f "$VESKTOP_CSS" ] && REST=$(sed \
        -e '/>>> toggle_theme managed >>>/,/<<< toggle_theme managed <<</d' \
        -e '\#catppuccin.github.io/discord/dist#d' "$VESKTOP_CSS")
    {
        printf '/* >>> toggle_theme managed >>> */\n'
        printf '@import url("https://catppuccin.github.io/discord/dist/catppuccin-%s-%s.theme.css");\n' "$FLAVOR" "$ACCENT_CHOICE"
        # Flatten Discord's background tokens onto the palette so the whole app
        # is the exact terminal/bar base. The chat pane reads base-lower and the
        # sidebars/server-rail/body read base-lowest, so pinning all base-* (plus
        # the legacy primary/secondary/tertiary) to ${base} gives one flat color
        # regardless of Discord's appearance (Dark/Darker/Midnight). Floating
        # popouts stay on crust so modals/menus read against the flat base.
        cat <<CSS
.theme-light, .theme-dark, .theme-darker, .theme-midnight,
.visual-refresh.theme-light, .visual-refresh.theme-dark,
.visual-refresh.theme-darker, .visual-refresh.theme-midnight {
  --background-base-low: ${base} !important;
  --background-base-lower: ${base} !important;
  --background-base-lowest: ${base} !important;
  --background-secondary-alt: ${base} !important;
  --background-surface-high: ${surface0} !important;
  --background-surface-higher: ${surface0} !important;
  --background-surface-highest: ${surface1} !important;
  --bg-surface-raised: ${base} !important;
  --background-primary: ${base} !important;
  --background-secondary: ${base} !important;
  --background-tertiary: ${base} !important;
  --background-floating: ${crust} !important;
  --app-frame-background: ${base} !important;
}
CSS
        printf '/* <<< toggle_theme managed <<< */\n'
        printf '%s' "$REST"
    } > "$VESKTOP_CSS"
fi

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

GTK_THEME_NAME="catppuccin-${FLAVOR}-${ACCENT_CHOICE}-standard+default"
if [ -d "/usr/share/themes/$GTK_THEME_NAME" ]; then
    gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME_NAME" 2>/dev/null || true
fi
gsettings set org.gnome.desktop.interface color-scheme "prefer-${NEW}" 2>/dev/null || true

ZED_SETTINGS="$HOME/.config/zed/settings.json"
if [ -f "$ZED_SETTINGS" ]; then
    # Direct swap: if NEW is dark, set mode to dark. If NEW is light, set mode to light.
    sed -i -E "s/\"mode\": \"(dark|light)\"/\"mode\": \"${NEW}\"/" "$ZED_SETTINGS"
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
