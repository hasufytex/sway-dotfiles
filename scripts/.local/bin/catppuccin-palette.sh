# Catppuccin palette: single source of truth for every dotfile color (mocha=dark, latte=light).

CATPPUCCIN_NAMES=(rosewater flamingo pink mauve red maroon peach yellow green teal \
  sky sapphire blue lavender text subtext1 subtext0 overlay2 overlay1 overlay0 \
  surface2 surface1 surface0 base mantle crust accent accent_fg white)

load_palette() {
  local flavor="${1:-mocha}"
  # 1. Accept a second argument for the accent, defaulting to blue if left blank
  local accent_choice="${2:-blue}"
  local json_file="$HOME/my-i3-dotfiles/palette.json"

  if [ ! -f "$json_file" ]; then
    echo "load_palette: error, missing $json_file" >&2
    return 1
  fi

  for color in $(jq -r ".$flavor.colors | keys[]" "$json_file"); do
    eval "$color=$(jq -r ".$flavor.colors.$color.hex" "$json_file")"
  done

  # 2. Dynamically assign the accent based on whatever word was passed in!
  eval "accent=\$$accent_choice"
  accent_fg=$base
  white=#ffffff
  export "${CATPPUCCIN_NAMES[@]}"
}

# "#cba6f7" -> "203;166;247" for ANSI truecolor (e.g. bash PS1 \e[38;2;...m).
hex2rgb() { local h=${1#\#}; printf '%d;%d;%d' "0x${h:0:2}" "0x${h:2:2}" "0x${h:4:2}"; }
