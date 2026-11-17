# Let XDG-aware apps (foot, GTK) find the desktop defaults installed in
# /usr/local/etc/xdg before the distro's /etc/xdg. Users' own ~/.config
# still wins over both.
case ":${XDG_CONFIG_DIRS:=/etc/xdg}:" in
    *:/usr/local/etc/xdg:*) ;;
    *) XDG_CONFIG_DIRS="/usr/local/etc/xdg:$XDG_CONFIG_DIRS" ;;
esac
export XDG_CONFIG_DIRS
