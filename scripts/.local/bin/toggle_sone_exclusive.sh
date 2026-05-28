#!/bin/bash
# Flip PipeWire's management of the Volt 1 so Sone can take the device
# in Exclusive output mode without PipeWire reclaiming it between tracks.
# Both output AND input must be released — the USB device shares its
# stream interface between capture and playback, so the mic being held
# locks the altset/rate and blocks Sone's exclusive rate switches.
# Re-running flips back to shared (desktop audio + mic).

CONF="$HOME/.config/wireplumber/wireplumber.conf.d/51-disable-volt.conf"
OUT="alsa_output.usb-Universal_Audio_Volt_1_24232036072027-00.analog-stereo"
IN="alsa_input.usb-Universal_Audio_Volt_1_24232036072027-00.analog-stereo"

if [ -e "$CONF" ]; then
    rm -f "$CONF"
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
    notify-send -a "Volt" "Exclusive mode" "Volt reserved for Sone (no mic)"
fi
