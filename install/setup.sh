#!/bin/bash
# Full machine setup: install approved packages, build AUR helper, stow configs, apply system files. Invoked by the bootstrap gist.
set -e

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
read_list() { grep -vE '^[[:space:]]*(#|$)' "$1"; }

# Faster/nicer pacman (mirror this machine)
sudo sed -i 's/^#\s*ParallelDownloads.*/ParallelDownloads = 20/; s/^#Color$/Color/' /etc/pacman.conf

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

# Custom C status bar: own repo, cloned once. Never re-cloned or pulled —
# local changes and git state there belong to the user.
if [ ! -d "$HOME/bar/.git" ]; then
  git clone https://github.com/hasufytex/bar.git "$HOME/bar"
fi
(cd "$HOME/bar" && make && make install)

# Stow (--adopt absorbs any pre-existing file, e.g. skel's ~/.bashrc; git checkout restores repo content)
cd "$DOTFILES"
stow --no-folding --adopt bash kitty mpv pipewire scripts sway system-env systemd yazi
git checkout -- .

# System files (tracked under system/): nvidia max-perf service + firefox VAAPI policy
sudo cp "$DOTFILES/system/etc/systemd/system/nvidia-max-perf.service" /etc/systemd/system/
sudo install -Dm644 "$DOTFILES/system/usr/lib/firefox/distribution/policies.json" \
  /usr/lib/firefox/distribution/policies.json

# swaylock PAM without pam_faillock (no self-lockout at the screen locker).
sudo install -Dm644 "$DOTFILES/system/etc/pam.d/swaylock" /etc/pam.d/swaylock

# SSH server hardening drop-in (key-only auth) for publicly port-forwarded sshd.
# Needs ~/.ssh/authorized_keys populated first; Tailscale SSH is unaffected.
sudo install -Dm644 "$DOTFILES/system/etc/ssh/sshd_config.d/20-hardening.conf" \
  /etc/ssh/sshd_config.d/20-hardening.conf

# Networking: systemd-networkd (wired DHCP) + resolved (Cloudflare DNS-over-TLS).
# Copied (not symlinked): the systemd-resolve/-network service users can't read configs under a 0700/0710 home.
sudo install -Dm644 "$DOTFILES/system/etc/systemd/network/20-wired.network" \
  /etc/systemd/network/20-wired.network
sudo install -Dm644 "$DOTFILES/system/etc/systemd/resolved.conf" \
  /etc/systemd/resolved.conf

# File sharing: Samba (Arch ships no smb.conf) + Avahi mDNS advertisement.
# The share dir must be writable by the connecting user; LAN is trusted by nftables.
sudo install -Dm644 "$DOTFILES/system/etc/samba/smb.conf" /etc/samba/smb.conf
sudo install -Dm644 "$DOTFILES/system/etc/avahi/services/smb.service" \
  /etc/avahi/services/smb.service
sudo install -d -o "$USER" -g "$USER" /srv/samba/phone

# Firewall ruleset: default-deny inbound (replaces the stock Arch config the
# nftables package ships).
sudo install -Dm644 "$DOTFILES/system/etc/nftables.conf" /etc/nftables.conf
sudo systemctl enable systemd-networkd systemd-networkd-wait-online systemd-resolved
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# Catppuccin wallpaper
mkdir -p "$HOME/Downloads"

# Initialize theme state
echo "dark" > "$HOME/.config/theme-state"
"$HOME/.local/bin/toggle_theme.sh" --apply || true

# Enable user services (stremio-service starts with graphical-session.target)
systemctl --user enable --now pipewire pipewire-pulse wireplumber
systemctl --user enable stremio-service

# Lock NVIDIA GPU to maximum performance clocks
sudo systemctl daemon-reload
sudo systemctl enable --now nvidia-max-perf

# File sharing (smb = smbd; skip nmb, iOS uses mDNS not NetBIOS)
sudo systemctl enable --now smb avahi-daemon

# Firewall + SSD trim
sudo systemctl enable --now nftables
sudo systemctl enable fstrim.timer

# Tailscale mesh VPN. Daemon only; joining the tailnet is a manual one-time step:
#   sudo tailscale up --ssh --accept-dns=false
# (interactive auth URL; --accept-dns=false keeps the Cloudflare DoT resolved.conf)
sudo systemctl enable --now tailscaled

# SSH server (key-only via the 20-hardening.conf drop-in above)
sudo systemctl enable --now sshd

echo "Done. Switch to a TTY and run 'sway-session' to launch sway."
