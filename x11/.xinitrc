#!/bin/sh

# Start i3
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=i3
export LIBVA_DRIVER_NAME=nvidia
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export GBM_BACKEND=nvidia-drm
export __GL_GSYNC_ALLOWED=1
export __GL_VRR_ALLOWED=1
[[ -f ~/.Xresources ]] && xrdb -merge ~/.Xresources
exec i3
