#!/bin/bash
# Full machine setup: install approved packages, build AUR helper, stow configs, apply system files. Invoked by the bootstrap gist.
set -e

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
read_list() { grep -vE '^[[:space:]]*(#|$)' "$1"; }

# Faster/nicer pacman (mirror this machine)
sudo sed -i 's/^#\s*ParallelDownloads.*/ParallelDownloads = 5/; s/^#Color$/Color/' /etc/pacman.conf

# Update + approved native packages
sudo pacman -Syu --noconfirm
mapfile -t PAC < <(read_list "$DOTFILES/install/pkglist-pacman.txt")
sudo pacman -S --needed --noconfirm "${PAC[@]}"

# yay (AUR helper)
if ! command -v yay &>/dev/null; then
  git clone https://aur.archlinux.org/yay.git /tmp/yay
  (cd /tmp/yay && makepkg -si --noconfirm)
  rm -rf /tmp/yay
fi

# Approved AUR packages
mapfile -t AUR < <(read_list "$DOTFILES/install/pkglist-aur.txt")
if [ "${#AUR[@]}" -gt 0 ]; then
  yay -S --needed --noconfirm "${AUR[@]}"
fi

# eww — AUR GPG key import is unreliable; build directly with check skipped
if ! command -v eww &>/dev/null; then
  tmpdir=$(mktemp -d)
  git clone https://aur.archlinux.org/eww.git "$tmpdir/eww"
  (cd "$tmpdir/eww" && makepkg -si --skippgpcheck --noconfirm)
  rm -rf "$tmpdir"
fi

# Stow (--adopt absorbs any pre-existing file, e.g. skel's ~/.bashrc; git checkout restores repo content)
cd "$DOTFILES"
stow --adopt bash brave eww kitty mangohud nvim pipewire scripts stremio sway system-env yazi zsh
git checkout -- .

# System files (tracked under system/): nvidia max-perf service + firefox VAAPI policy
sudo cp "$DOTFILES/system/etc/systemd/system/nvidia-max-perf.service" /etc/systemd/system/
sudo install -Dm644 "$DOTFILES/system/usr/lib/firefox/distribution/policies.json" \
  /usr/lib/firefox/distribution/policies.json

# Networking: systemd-networkd (wired DHCP) + resolved
sudo install -Dm644 "$DOTFILES/system/etc/systemd/network/20-wired.network" \
  /etc/systemd/network/20-wired.network
sudo systemctl enable systemd-networkd systemd-resolved
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# Catppuccin wallpaper
mkdir -p "$HOME/Downloads"

# Initialize theme state
echo "dark" > "$HOME/.config/theme-state"
"$HOME/.local/bin/toggle_theme.sh" --apply || true

# Default shell to bash
if [ "$SHELL" != "/bin/bash" ]; then
  chsh -s /bin/bash
fi

# Enable user services (stremio-service is not a unit — it autostarts in-session via dex)
systemctl --user enable --now pipewire pipewire-pulse wireplumber

# Lock NVIDIA GPU to maximum performance clocks
sudo systemctl daemon-reload
sudo systemctl enable --now nvidia-max-perf

# Firewall + SSD trim
sudo systemctl enable --now nftables
sudo systemctl enable fstrim.timer

# Ollama (only if approved/installed)
if pacman -Qq ollama-cuda &>/dev/null; then
  sudo systemctl enable --now ollama
fi

echo "Done. Switch to a TTY and run 'sway-session' to launch sway."
