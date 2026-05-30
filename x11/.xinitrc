#!/bin/sh
# X11 session init: sets NVIDIA env vars and launches i3.
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=i3
export LIBVA_DRIVER_NAME=nvidia
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export GBM_BACKEND=nvidia-drm
export __GL_GSYNC_ALLOWED=1
export __GL_VRR_ALLOWED=1
export __GL_SYNC_TO_VBLANK=0
export MANGOHUD=1
[[ -f ~/.Xresources ]] && xrdb -merge ~/.Xresources

systemctl --user import-environment DISPLAY XAUTHORITY

exec i3
