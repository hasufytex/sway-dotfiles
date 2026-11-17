#!/bin/bash
# Link this repo's system layers into place. See README.md.
set -euo pipefail

usage() {
    cat <<'EOF'
usage: install.sh [--root DIR --host NAME] [--distro ID] [--dry-run]
       install.sh --uninstall [--root DIR] [--dry-run]

Layers, each a mirror of / (two layers may not provide the same path):
  common/          every machine
  distros/<ID>/    ID from <root>/etc/os-release, or --distro
  hosts/<NAME>/    NAME from uname -n; required with --root

Files under etc/skel/ are copied, because useradd copies skel into each new
home and every user must own their copy. Everything else becomes a relative
symlink into this repo, so links resolve the same from a live USB
(--root /mnt/gentoo) and after boot, wherever the repo sits under the root.

A file that is replaced is kept as <path>.pre-sway-dotfiles. What was
installed is recorded in <root>/var/lib/sway-dotfiles/manifest: installing
again removes links for files that left the repo, and --uninstall restores
the previous state.

  --root DIR    install into the system mounted at DIR (default /)
  --host NAME   host layer to use
  --distro ID   distro layer to use
  -n, --dry-run print what would change, change nothing
  --uninstall   remove everything recorded in the manifest
EOF
}

die() { echo "install.sh: $*" >&2; exit 1; }
warn() { echo "warning: $*" >&2; }

repo=$(dirname "$(readlink -f "$0")")
root=/
host=
distro=
dry=0
action=install
suffix=.pre-sway-dotfiles

while [ $# -gt 0 ]; do
    case $1 in
    --root) root=${2:?--root needs a directory}; shift 2 ;;
    --host) host=${2:?--host needs a name}; shift 2 ;;
    --distro) distro=${2:?--distro needs an ID}; shift 2 ;;
    -n | --dry-run) dry=1; shift ;;
    --uninstall) action=uninstall; shift ;;
    -h | --help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
    esac
done

[ -d "$root" ] || die "no such directory: $root"
root=$(readlink -f "$root")
prefix=${root%/}   # "" for the running system
manifest=$prefix/var/lib/sway-dotfiles/manifest

if [ "$dry" = 0 ] && [ ! -w "${prefix:-/}" ]; then
    die "cannot write to ${prefix:-/}: run as root, or use --dry-run"
fi
if [ -n "$prefix" ]; then
    case $repo/ in
    "$prefix"/*) ;;
    *) die "the repo ($repo) must be inside --root ($root), or the links would dangle after boot" ;;
    esac
else
    case $repo/ in
    /home/* | /root/*) warn "the repo is in a home directory; every user's desktop will depend on it" ;;
    esac
fi

say() { printf '%-8s %s\n' "$1" "$2"; }
run() { [ "$dry" = 1 ] || "$@"; }

# Old manifest: mode<TAB>path, one per line.
declare -A old_mode=()
if [ -r "$manifest" ]; then
    while IFS=$'\t' read -r mode path; do
        [ -n "$path" ] && old_mode[$path]=$mode
    done <"$manifest"
fi

# A link of ours points into the repo (even if that file is gone now).
is_our_link() {
    [ -L "$1" ] || return 1
    case $(readlink -m "$1") in "$repo"/*) return 0 ;; esac
    return 1
}

prune_dirs() {
    local d
    d=$(dirname "$1")
    while [ "$d" != "${prefix:-/}" ] && [ "$d" != / ] && rmdir "$d" 2>/dev/null; do
        d=$(dirname "$d")
    done
}

# Undo one manifest entry: remove our file, then restore the backup.
remove_one() {
    local mode=$1 path=$2 dest=$prefix$2
    if [ "$mode" = link ]; then
        if is_our_link "$dest"; then
            say remove "$path"
            run rm -f "$dest"
        elif [ -e "$dest" ] || [ -L "$dest" ]; then
            warn "$path no longer links into the repo; left alone"
            return
        fi
    elif [ -e "$dest" ]; then
        say remove "$path"
        run rm -f "$dest"
    fi
    if [ -e "$dest$suffix" ] || [ -L "$dest$suffix" ]; then
        say restore "$path$suffix -> $path"
        run mv "$dest$suffix" "$dest"
    elif [ "$dry" = 0 ]; then
        prune_dirs "$dest"
    fi
}

# Move whatever is at dest aside, unless it is already ours.
make_room() {
    local path=$1 dest=$prefix$1
    [ -e "$dest" ] || [ -L "$dest" ] || return 0
    is_our_link "$dest" && return 0
    [ "${old_mode[$path]:-}" = copy ] && return 0
    if [ -e "$dest$suffix" ] || [ -L "$dest$suffix" ]; then
        die "$path$suffix already exists; move one of them away first"
    fi
    say backup "$path -> $path$suffix"
    run mv "$dest" "$dest$suffix"
}

install_one() {
    local path=$1 src=$2 dest=$prefix$1 target
    case $path in
    /etc/skel/*)
        if [ -f "$dest" ] && [ ! -L "$dest" ] && cmp -s "$src" "$dest"; then
            say ok "$path"
            return
        fi
        make_room "$path"
        say copy "$path"
        run mkdir -p "$(dirname "$dest")"
        run install -m 0644 "$src" "$dest"
        ;;
    *)
        target=$(realpath -m --relative-to="$(dirname "$dest")" "$src")
        if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$target" ]; then
            say ok "$path"
            return
        fi
        make_room "$path"
        say link "$path -> $target"
        run mkdir -p "$(dirname "$dest")"
        run ln -sfn "$target" "$dest"
        ;;
    esac
}

[ "$dry" = 1 ] && echo "(dry run: nothing is changed)"

if [ "$action" = uninstall ]; then
    [ -r "$manifest" ] || die "nothing installed: $manifest not found"
    for path in $(printf '%s\n' "${!old_mode[@]}" | sort -r); do
        remove_one "${old_mode[$path]}" "$path"
    done
    say remove "${manifest#"$prefix"}"
    run rm -f "$manifest"
    [ "$dry" = 1 ] || prune_dirs "$manifest"
    exit 0
fi

# Pick the layers.
if [ -z "$distro" ] && [ -r "$prefix/etc/os-release" ]; then
    distro=$(sed -n 's/^ID=//p' "$prefix/etc/os-release" | tr -d '"'\')
fi
if [ -z "$host" ]; then
    [ -z "$prefix" ] || die "--host is required with --root (the live system's hostname is not the target's)"
    host=$(uname -n)
fi
layers=("$repo/common")
for layer in "distros/$distro" "hosts/$host"; do
    if [ -n "${layer#*/}" ] && [ -d "$repo/$layer" ]; then
        layers+=("$repo/$layer")
    else
        warn "no $layer layer in the repo; skipping it"
    fi
done
echo "layers: ${layers[*]#"$repo"/}"

# Collect every file, refusing duplicates across layers.
declare -A src_of=()
for layer in "${layers[@]}"; do
    while IFS= read -r -d '' f; do
        path=${f#"$layer"}
        if [ -n "${src_of[$path]:-}" ]; then
            die "$path is provided by both ${src_of[$path]#"$repo"/} and ${f#"$repo"/}"
        fi
        src_of[$path]=$f
    done < <(find "$layer" \( -type f -o -type l \) -print0)
done

unreadable=$(find "${layers[@]}" ! -perm -o+r -print -quit)
[ -z "$unreadable" ] || warn "not world-readable, other users cannot use it: ${unreadable#"$repo"/}"

# Drop what left the repo since the last install, then install the rest.
for path in $(printf '%s\n' "${!old_mode[@]}" | sort -r); do
    [ -n "${src_of[$path]:-}" ] || remove_one "${old_mode[$path]}" "$path"
done
paths=$(printf '%s\n' "${!src_of[@]}" | sort)
for path in $paths; do
    install_one "$path" "${src_of[$path]}"
done

if [ "$dry" = 0 ]; then
    mkdir -p "$(dirname "$manifest")"
    for path in $paths; do
        case $path in /etc/skel/*) mode=copy ;; *) mode=link ;; esac
        printf '%s\t%s\n' "$mode" "$path"
    done >"$manifest.new"
    mv "$manifest.new" "$manifest"
fi

# On the running system, point out commands the configs expect.
if [ -z "$prefix" ]; then
    missing=
    for cmd in sway swaymsg swayidle swaylock foot wmenu-run grim slurp wl-copy jq \
        pactl gsettings dolphin dbus-run-session gnome-keyring-daemon bar; do
        command -v "$cmd" >/dev/null || missing="$missing $cmd"
    done
    [ -z "$missing" ] || warn "commands used by the configs but not installed:$missing"
fi
