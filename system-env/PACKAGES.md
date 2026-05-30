# Packages required by this dotfiles repo (Arch)

```
sudo pacman -S fzf bat feh
```

| Package | Used for |
|---|---|
| `fzf` | Terminal fuzzy finder. Ctrl-T / Ctrl-R / Alt-C in zsh via `/usr/share/fzf/key-bindings.zsh`. |
| `bat` | Syntax-highlighted `cat`. `BAT_THEME` follows the dark/light toggle via `~/.config/theme-colors.sh`. |
| `feh` | Sets the desktop wallpaper from `~/Pictures/wallpapers/catppuccin-{mocha,latte}.png`. |

Optional, AUR:

```
paru -S catppuccin-gtk-theme-mocha catppuccin-gtk-theme-latte
```

The toggle script falls back to Adwaita/Adwaita-dark via `gsettings color-scheme` if these aren't installed, so the AUR step is purely cosmetic.

For bat syntax highlighting in the matching palette, drop the official Catppuccin `.tmTheme` files into `~/.config/bat/themes/` (from https://github.com/catppuccin/bat) and run `bat cache --build`.

## Stow packages introduced

```
cd ~/my-i3-dotfiles
```

(All other stow packages — `i3`, `kitty`, `nvim`, `yazi`, `zsh`, `system-env`, `pipewire` — were already in place.)
