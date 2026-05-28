#!/bin/bash
# Toggle "exclusive Sone mode" by writing a WirePlumber drop-in that
# disables both the Volt's input and output PipeWire nodes. The Volt
# is a USB Audio Class device whose capture and playback share one
# stream interface — both directions must be released for Sone to be
# able to switch rates exclusively on the playback side.
#
# Caveat: while the toggle is on, the Volt disappears from PipeWire's
# device list and so from Sone's output-device dropdown. Pre-select
# the Volt in Sone while in shared mode; Sone remembers the choice
# and opens /dev/snd/pcmC0D0p directly via ALSA in exclusive mode.
# No desktop / Discord / browser audio while toggled on.
#
# Writes /tmp/sone_audio_mode for the i3status read_file block:
# present → "Audio: E", absent → format_bad falls back to "Audio: S".

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
