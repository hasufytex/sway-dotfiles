# One-window scratchpad shortcut

`Mod+Shift+minus` runs `sway-scratchpad-single`, which admits at most one window
to the scratchpad through that shortcut, initially leaving the window visible
on the current workspace. It counts hidden and shown scratchpad
windows, across every workspace. If occupied, the shortcut leaves both windows
where they are. Pressing it on the existing scratchpad window still hides it.
`Mod+minus` and the bar icons continue to show and hide the existing window.

Restore the existing window to ordinary tiling to free the slot. In this config,
`Mod+p` toggles floating; use it on the shown scratchpad window to tile it.
Multiwindow containers and floating groups are refused when adding a new entry.

The helper requires Bash, `swaymsg`, `jq`, and `flock`. It reads one tree per
keypress and sends at most one command request. Adding a window moves it to the
scratchpad and immediately shows it again in that same request; hiding sends
only the move command. A nonblocking lock serializes
admission checks; there are no subscriptions, timers, or background processes.

Install the script through the existing Stow `scripts` package and reload Sway:

```sh
stow --dir="$HOME/Projects/sway-dotfiles" --target="$HOME" scripts sway
swaymsg reload
```

This guards the shortcut, rather than imposing a compositor-wide restriction.
Direct Sway commands and other bindings can bypass it. Existing scratchpad
contents are left untouched when installing or reloading the configuration.

Run the simulated checks without moving any desktop windows:

```sh
python3 tests/test-sway-scratchpad-single.py
```
