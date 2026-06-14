#!/bin/bash
# Full machine setup: install approved packages, build from source, stow configs,
# deploy system files, and enable services. Invoked by the bootstrap gist.
set -e

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
read_list() { grep -vE '^[[:space:]]*(#|$)' "$1"; }

# ─────────────────────────────────────────────────────────────────────────────
# Packages
# ─────────────────────────────────────────────────────────────────────────────

# Tune pacman before installing: parallelize downloads and colorize output.
sudo sed -i 's/^#\s*ParallelDownloads.*/ParallelDownloads = 20/; s/^#Color$/Color/' /etc/pacman.conf

# Sync the system, then install the approved native packages.
sudo pacman -Syu --noconfirm
mapfile -t PAC < <(read_list "$DOTFILES/install/pkglist-pacman.txt")
sudo pacman -S --needed --noconfirm "${PAC[@]}"

# yay is the AUR helper; build it from the AUR once, then use it for the rest.
if ! command -v yay &>/dev/null; then
  git clone https://aur.archlinux.org/yay.git /tmp/yay
  (cd /tmp/yay && makepkg -si --noconfirm)
  rm -rf /tmp/yay
fi

# Approved AUR packages.
mapfile -t AUR < <(read_list "$DOTFILES/install/pkglist-aur.txt")
if [ "${#AUR[@]}" -gt 0 ]; then
  yay -S --needed --noconfirm "${AUR[@]}"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Build from source
# ─────────────────────────────────────────────────────────────────────────────

# Custom C status bar: lives in its own repo, cloned only once. It is never
# re-cloned or pulled — local changes and git state there belong to the user.
if [ ! -d "$HOME/bar/.git" ]; then
  git clone https://github.com/hasufytex/bar.git "$HOME/bar"
fi
(cd "$HOME/bar" && make && make install)

# ─────────────────────────────────────────────────────────────────────────────
# User configs (GNU Stow)
# ─────────────────────────────────────────────────────────────────────────────

# Symlink each package into $HOME. --adopt pulls any pre-existing file (e.g. the
# skel ~/.bashrc) into the repo; `git checkout` then restores the repo's content,
# so the end state is the tracked config with no "file already exists" errors.
cd "$DOTFILES"
stow --no-folding --adopt bash kitty mpv pipewire scripts sway system-env systemd yazi
git checkout -- .

# ─────────────────────────────────────────────────────────────────────────────
# Git config
# ─────────────────────────────────────────────────────────────────────────────

# `git ask-claude`: generate a one-line commit message from the staged diff via
# Claude Code, then commit with it.
git config --global alias.ask-claude '!f() { msg=$(git diff --cached | claude -p "Write a one-line git commit message for this diff in the format: verb: description. Output only the message, nothing else."); git commit -m "$msg"; }; f'

# ─────────────────────────────────────────────────────────────────────────────
# System files
#
# Everything under system/ is copied (not stowed): systemd service users and
# other system daemons can't read files under a 0700/0710 home directory.
# ─────────────────────────────────────────────────────────────────────────────

# GPU: pin NVIDIA to maximum performance clocks (service enabled further below).
sudo cp "$DOTFILES/system/etc/systemd/system/nvidia-max-perf.service" /etc/systemd/system/

# Boot/initramfs: install the mkinitcpio config (no `kms` hook, empty MODULES) and
# rebuild, so the proprietary-nvidia GSP firmware never gets bundled into the 196M
# /boot. The kernel package already built an initramfs with the stock config during
# package install above, so a regeneration here is required for the change to apply.
sudo install -Dm644 "$DOTFILES/system/etc/mkinitcpio.conf" /etc/mkinitcpio.conf
sudo mkinitcpio -P

# Firefox: enterprise policy enabling hardware-accelerated video (VAAPI).
sudo install -Dm644 "$DOTFILES/system/usr/lib/firefox/distribution/policies.json" /usr/lib/firefox/distribution/policies.json

# ttyd web terminal + its cert-renewal units. The service runs `login` (PAM auth)
# over HTTPS on the tailnet IP:443 using a Tailscale-issued cert (renewed by
# ttyd-cert.timer). These unit files must exist before ttyd is enabled below; the
# service itself only comes up after `tailscale up` + MagicDNS/HTTPS are enabled.
sudo cp "$DOTFILES/system/etc/systemd/system/ttyd.service" /etc/systemd/system/
sudo cp "$DOTFILES/system/etc/systemd/system/ttyd-cert.service" /etc/systemd/system/
sudo cp "$DOTFILES/system/etc/systemd/system/ttyd-cert.timer" /etc/systemd/system/

# swaylock PAM stack without pam_faillock, so a fat-fingered password at the
# screen locker can never lock the account out.
sudo install -Dm644 "$DOTFILES/system/etc/pam.d/swaylock" /etc/pam.d/swaylock

# Networking: systemd-networkd (wired DHCP) + resolved (Cloudflare DNS-over-TLS).
sudo install -Dm644 "$DOTFILES/system/etc/systemd/network/20-wired.network" /etc/systemd/network/20-wired.network
sudo install -Dm644 "$DOTFILES/system/etc/systemd/resolved.conf" /etc/systemd/resolved.conf

# File sharing: Samba config (Arch ships none) + Avahi mDNS advert so the share
# is discoverable. The share dir is owned by the connecting user.
sudo install -Dm644 "$DOTFILES/system/etc/samba/smb.conf" /etc/samba/smb.conf
sudo install -Dm644 "$DOTFILES/system/etc/avahi/services/smb.service" /etc/avahi/services/smb.service
sudo install -d -o "$USER" -g "$USER" /srv/samba/phone

# Firewall: default-deny inbound ruleset (replaces the stock config the nftables
# package ships).
sudo install -Dm644 "$DOTFILES/system/etc/nftables.conf" /etc/nftables.conf

# Swap: a 16 GiB disk swapfile as an OOM fallback. Created here (binary, can't be
# tracked in git); swappiness=10 keeps it idle until RAM is nearly exhausted.
if ! swapon --show=NAME --noheadings | grep -qx /swapfile; then
  if [ ! -f /swapfile ]; then
    sudo fallocate -l 16G /swapfile        # ext4: fallocate is safe for swap
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
  fi
fi
sudo install -Dm644 "$DOTFILES/system/etc/sysctl.d/99-swap.conf" /etc/sysctl.d/99-swap.conf
sudo install -Dm644 "$DOTFILES/system/etc/systemd/system/swapfile.swap" /etc/systemd/system/swapfile.swap

# ─────────────────────────────────────────────────────────────────────────────
# Local state & theme
# ─────────────────────────────────────────────────────────────────────────────

# Wallpaper download target.
mkdir -p "$HOME/Downloads"

# Seed the theme to dark and render every themed config from its template.
echo "dark" > "$HOME/.config/theme-state"
"$HOME/.local/bin/toggle_theme.sh" --apply || true

# ─────────────────────────────────────────────────────────────────────────────
# Enable services
# ─────────────────────────────────────────────────────────────────────────────

# Pick up the unit files copied above.
sudo systemctl daemon-reload

# Apply swappiness now and activate the fallback swapfile.
sudo sysctl --system >/dev/null
sudo systemctl enable --now swapfile.swap

# Networking: bring up networkd + resolved, and point resolv.conf at the resolved
# stub so DNS goes through the Cloudflare DoT config.
sudo systemctl enable systemd-networkd systemd-networkd-wait-online systemd-resolved
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# Audio stack + Stremio (the latter starts with graphical-session.target).
systemctl --user enable --now pipewire pipewire-pulse wireplumber
systemctl --user enable stremio-service

# GPU max-performance lock.
sudo systemctl enable --now nvidia-max-perf

# File sharing: smb = smbd only (skip nmb — iOS discovers via mDNS, not NetBIOS).
sudo systemctl enable --now smb avahi-daemon

# Firewall + periodic SSD trim.
sudo systemctl enable --now nftables
sudo systemctl enable fstrim.timer

# Periodic pacman cache cleanup (paccache, from pacman-contrib): keeps the last 3
# versions of each package weekly, so the cache can't grow unbounded again.
sudo systemctl enable --now paccache.timer

# Tailscale mesh VPN. Daemon only; joining the tailnet is a manual one-time step:
#   sudo tailscale up --ssh --accept-dns=false
# (interactive auth URL; --accept-dns=false keeps the Cloudflare DoT resolved.conf)
# sudo systemctl enable --now tailscaled

# Web terminal + its TLS cert-renewal timer. Enabled now, but they only start
# cleanly once the tailnet IP exists (after `tailscale up` + MagicDNS/HTTPS).
# sudo systemctl enable ttyd ttyd-cert.timer

echo "Done. Switch to a TTY and run 'sway-session' to launch sway."
