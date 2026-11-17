# NVIDIA (RTX 3060, proprietary driver). Sourced by sway-session and
# plasma-session before the compositor starts.
export GBM_BACKEND=nvidia-drm
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export LIBVA_DRIVER_NAME=nvidia
export __GL_GSYNC_ALLOWED=1
export __GL_VRR_ALLOWED=1
export __GL_SYNC_TO_VBLANK=0
export MOZ_DISABLE_RDD_SANDBOX=1   # required by nvidia-vaapi-driver; sandbox blocks NVDEC init

# sway refuses to start on the proprietary driver without this flag.
SWAY_FLAGS="$SWAY_FLAGS --unsupported-gpu"
