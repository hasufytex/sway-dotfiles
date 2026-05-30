# Packages required by this dotfiles repo (Arch)

```
sudo pacman -S fzf bat feh
```

| Package | Used for |
|---|---|
| `fzf` | Terminal fuzzy finder. Ctrl-T / Ctrl-R / Alt-C in zsh via `/usr/share/fzf/key-bindings.zsh`. |
| `bat` | Syntax-highlighted `cat`. `BAT_THEME` follows the dark/light toggle via `~/.config/theme-colors.sh`. |
| `feh` | Sets the desktop wallpaper from `~/Downloads/1378545.jpg` (see `WALLPAPER` in `toggle_theme.sh`). |

Optional, AUR:

```
paru -S catppuccin-gtk-theme-mocha catppuccin-gtk-theme-latte
```

The toggle script falls back to Adwaita/Adwaita-dark via `gsettings color-scheme` if these aren't installed, so the AUR step is purely cosmetic.

For bat syntax highlighting in the matching palette, drop the official Catppuccin `.tmTheme` files into `~/.config/bat/themes/` (from https://github.com/catppuccin/bat) and run `bat cache --build`.

## Stow packages

```
cd ~/my-i3-dotfiles
stow i3 eww kitty nvim pipewire scripts system-env system-xorg x11 yazi zsh
```
