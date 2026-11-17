# sway-dotfiles

A system-wide Sway desktop: every user on the machine gets the same sway
config, bar toggle, launcher, terminal, theming and audio setup, and can
still override any of it in their own `~/.config`.

The repo lives at **`/usr/local/src/sway-dotfiles`** (the custom bar sits
next to it at `/usr/local/src/bar`). `install.sh` links the files into the
standard system paths; nothing in the configs or scripts refers to the
repo's location.

## Layout

Each layer is a mirror of `/`:

| Layer | Used on | Holds |
| --- | --- | --- |
| `common/` | every machine | sway config, scripts, theming, skel |
| `distros/<ID>/` | `ID` from `/etc/os-release` | how the distro starts session services |
| `hosts/<hostname>/` | `uname -n` | monitor outputs, GPU env, audio interface |

Where things end up:

| Path | What |
| --- | --- |
| `/usr/local/etc/sway/config` | main sway config, used by `sway-session` when the user has no `~/.config/sway/config` |
| `/usr/local/etc/sway/config.d/` | distro and host sway parts |
| `/usr/local/etc/desktop-session.d/*.sh` | host env sourced by `sway-session` and `plasma-session` (sets `SWAY_FLAGS`) |
| `/usr/local/bin/` | `sway-session`, `plasma-session`, `bar-toggle`, screenshot scripts, `sunshine-session`, `sway-headless-fallback` |
| `/usr/local/etc/xdg/` | foot and GTK settings; `/etc/profile.d/sway-dotfiles.sh` puts this first in `XDG_CONFIG_DIRS` so the distro's own `/etc/xdg` and `/etc/gtk-3.0` files stay untouched |
| `/etc/xdg/kdeglobals`, `/etc/xdg/mimeapps.list` | Breeze Dark for Qt apps, Firefox as default browser |
| `/etc/swaylock/config`, `/etc/fonts/local.conf`, `/etc/mpv/mpv.conf` | lock colour, font rendering, mpv |
| `/etc/pipewire/…`, `/etc/wireplumber/…` | PipeWire and WirePlumber drop-ins |
| `/etc/skel/.bashrc`, `/etc/skel/.bash_profile` | copied into new homes (`~/.local/bin` on `PATH`) |
| `/usr/local/share/sway-dotfiles/sunshine.conf` | opt-in Sunshine snippet (see below) |

Lookup order is always: the user's own `~/.config` first, then these
system-wide files. A user can also add sway snippets in
`~/.config/sway/config.d/`, which the main config reads last.

## Installing

```sh
sudo ./install.sh --dry-run   # show what would change
sudo ./install.sh
```

Everything except `etc/skel/` becomes a relative symlink into the repo, so
editing the repo changes every user's desktop immediately (sway: run
`swaymsg reload` or log in again). Skel files are copied, because each new user
must own their copy. A file that is replaced is kept as
`<path>.pre-sway-dotfiles`; on Gentoo that is only the two `/etc/skel` files,
and later `app-shells/bash` updates will offer `._cfg` versions of them.

`install.sh` records what it installed in `/var/lib/sway-dotfiles/manifest`.
Running it again removes links for files that have left the repo.
`sudo ./install.sh --uninstall` restores the previous state.

The bar is built and installed from its own repo:

```sh
cd /usr/local/src/bar && make && sudo make install PREFIX=/usr/local
```

## A new install, from the live USB

```sh
git clone https://github.com/hasufytex/sway-dotfiles /mnt/gentoo/usr/local/src/sway-dotfiles
git clone https://github.com/hasufytex/bar /mnt/gentoo/usr/local/src/bar
/mnt/gentoo/usr/local/src/sway-dotfiles/install.sh --root /mnt/gentoo --host <new-hostname>
```

The links are relative, so they work after boot. If the machine is new, add
`hosts/<new-hostname>/` first (copy `hosts/gentoo/` and change the output
names, GPU env and audio device). For another distro, add
`distros/<ID>/usr/local/etc/sway/config.d/` with that distro's way of
starting PipeWire, the portals and the polkit agent. Build the bar from the
chroot once its dependencies are installed.

## Permissions

The tree must be readable by every user and writable only by admins, since
everything in it runs inside every user's session:

```sh
sudo chown -R root:wheel /usr/local/src/sway-dotfiles /usr/local/src/bar
sudo chmod -R g+w,o-w /usr/local/src/sway-dotfiles /usr/local/src/bar
sudo find /usr/local/src/sway-dotfiles /usr/local/src/bar -type d -exec chmod g+s {} +
sudo git config --system --add safe.directory /usr/local/src/sway-dotfiles
sudo git config --system --add safe.directory /usr/local/src/bar
git -C /usr/local/src/sway-dotfiles config core.sharedRepository group
git -C /usr/local/src/bar config core.sharedRepository group
```

`safe.directory` is needed because git refuses to work in a repo owned by
another user (root).

`install.sh` warns about repo files that other users cannot read.

## New users

```sh
sudo useradd -m -G video,audio -s /bin/bash <name>
```

`video` is required for the NVIDIA device files. They log in on a TTY and run
`sway-session`.

## Sunshine (opt-in)

Sunshine is not started for everyone: its ports can only be bound once, and
its pairing data is per user. To enable it for yourself:

```sh
mkdir -p ~/.config/sway/config.d
ln -s /usr/local/share/sway-dotfiles/sunshine.conf ~/.config/sway/config.d/
```

This also enables `sway-headless-fallback`, which keeps a virtual output
alive while no real monitor is active.
