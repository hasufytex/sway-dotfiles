#!/bin/bash
# Toggles exclusive ALSA mode for Sone by disabling the Universal Audio Volt in WirePlumber.
CONF="$HOME/.config/wireplumber/wireplumber.conf.d/51-disable-volt.conf"
OUT="alsa_output.usb-Universal_Audio_Volt_1_24232036072027-00.analog-stereo"
IN="alsa_input.usb-Universal_Audio_Volt_1_24232036072027-00.analog-stereo"
STATE="/tmp/sone_audio_mode"

if [ -e "$STATE" ]; then
    rm -f "$CONF" "$STATE"
    systemctl --user restart wireplumber
    notify-send -a "Volt" "Shared mode" "Desktop audio + mic restored"
else
    mkdir -p "$(dirname "$CONF")"
    cat > "$CONF" <<EOF
monitor.alsa.rules = [
  {
    matches = [
      { node.name = "$OUT" }
      { node.name = "$IN" }
    ]
    actions = {
      update-props = {
        node.disabled = true
      }
    }
  }
]
EOF
    systemctl --user restart wireplumber
    echo "Audio: E" > "$STATE"
    notify-send -a "Volt" "Exclusive mode" "Volt reserved for Sone (no mic)"
fi

killall -SIGUSR1 i3status 2>/dev/null || true
