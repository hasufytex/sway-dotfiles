#!/bin/bash
# Capture selected area and copy to clipboard.
grim -g "$(slurp)" - | wl-copy -t image/png
