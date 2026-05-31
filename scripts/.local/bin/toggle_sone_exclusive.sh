#!/bin/bash
# Toggle exclusive ALSA for Sone: switch the Volt to an output-only profile (mic off) and hand it to Sone by moving default playback away and suspending the PipeWire sink so hw:0,0 is free, while keeping the Volt sink visible so Sone still lists and opens it directly.
CARD="alsa_card.usb-Universal_Audio_Volt_1_24232036072027-00"
OUT="alsa_output.usb-Universal_Audio_Volt_1_24232036072027-00.analog-stereo"
STATE="/tmp/sone_audio_mode"

rm -f "$HOME/.config/wireplumber/wireplumber.conf.d/51-disable-volt.conf"

wait_sink() {
    for _ in $(seq 1 50); do
        pactl list short sinks 2>/dev/null | grep -q "$1" && return 0
        sleep 0.1
    done
    return 1
}

if [ -e "$STATE" ]; then
    pactl set-card-profile "$CARD" output:analog-stereo+input:analog-stereo
    wait_sink "$OUT"
    pactl suspend-sink "$OUT" 0
    pactl set-default-sink "$OUT"
    rm -f "$STATE"
    notify-send -a "Volt" "Shared mode" "Desktop audio + mic restored"
else
    pactl set-card-profile "$CARD" output:analog-stereo
    wait_sink "$OUT"
    alt=$(pactl list short sinks 2>/dev/null | awk -v volt="$OUT" '$2 != volt {print $2; exit}')
    [ -n "$alt" ] && pactl set-default-sink "$alt"
    pactl suspend-sink "$OUT" 1
    echo "Audio: E" > "$STATE"
    notify-send -a "Volt" "Exclusive mode" "Volt reserved for Sone (no mic)"
fi

killall -SIGUSR1 i3status 2>/dev/null || true
