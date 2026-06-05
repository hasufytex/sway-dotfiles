#!/bin/bash
# Toggle exclusive ALSA for Sone: enter frees the Volt's hw:0,0 for Sone (mic off via output-only profile, default moved away, sink suspended); exit Stops Sone to release the device (Pause keeps it held), restores the duplex profile and mic, and snaps the Volt back to default pulling every stream with it.
CARD="alsa_card.usb-Universal_Audio_Volt_1_24232036072027-00"
OUT="alsa_output.usb-Universal_Audio_Volt_1_24232036072027-00.analog-stereo"
MPRIS="org.mpris.MediaPlayer2.io.github.lullabyX.sone"
STATE="/tmp/sone_audio_mode"

rm -f "$HOME/.config/wireplumber/wireplumber.conf.d/51-disable-volt.conf"

volt_pcm() {
    local idx; idx=$(readlink /proc/asound/V1 2>/dev/null | grep -oE '[0-9]+')
    [ -n "$idx" ] && echo "/dev/snd/pcmC${idx}D0p"
}

wait_sink() {
    for _ in $(seq 1 50); do
        pactl list short sinks 2>/dev/null | grep -q "$1" && return 0
        sleep 0.1
    done
    return 1
}

if [ -e "$STATE" ]; then
    pcm=$(volt_pcm)
    if [ -n "$pcm" ] && fuser "$pcm" 2>/dev/null | grep -q .; then
        busctl --user call "$MPRIS" /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player Stop 2>/dev/null
        for _ in $(seq 1 30); do fuser "$pcm" 2>/dev/null | grep -q . || break; sleep 0.1; done
    fi
    pactl set-card-profile "$CARD" output:analog-stereo+input:analog-stereo
    if wait_sink "$OUT"; then
        pactl suspend-sink "$OUT" 0
        pactl set-default-sink "$OUT"
        vid=$(pactl list short sinks 2>/dev/null | awk -v n="$OUT" '$2==n{print $1}')
        for si in $(pactl list short sink-inputs 2>/dev/null | cut -f1); do
            pactl move-sink-input "$si" "$vid" 2>/dev/null
        done
        rm -f "$STATE"
        notify-send -a "Volt" "Shared mode" "Desktop audio + mic restored"
    else
        notify-send -a "Volt" "Volt still busy" "Disable Exclusive in Sone, then toggle again"
    fi
else
    pactl set-card-profile "$CARD" output:analog-stereo
    wait_sink "$OUT"
    alt=$(pactl list short sinks 2>/dev/null | awk -v volt="$OUT" '$2 != volt {print $2; exit}')
    [ -n "$alt" ] && pactl set-default-sink "$alt"
    pactl suspend-sink "$OUT" 1
    echo "Audio: E" > "$STATE"
    notify-send -a "Volt" "Exclusive mode" "Volt reserved for Sone (no mic)"
fi
