#!/bin/bash
# Capture selected area and copy to clipboard.
maim -u -s | xclip -selection clipboard -t image/png
