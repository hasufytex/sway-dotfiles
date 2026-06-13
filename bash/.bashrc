# Bash config: history, completion, prompt, aliases, theme env, fzf, yazi.
# If not running interactively, don't do anything
[[ $- != *i* ]] && return

HISTFILE=~/.bash_history
HISTSIZE=10000
HISTFILESIZE=10000
HISTCONTROL=ignoredups
shopt -s histappend
PROMPT_COMMAND='history -a; history -n'

[ -f /usr/share/bash-completion/bash_completion ] && . /usr/share/bash-completion/bash_completion

bind 'set show-all-if-ambiguous on'
bind 'set menu-complete-display-prefix on'
bind 'TAB:menu-complete'
bind '"\e[Z": menu-complete-backward'

PS1='\[${PS1_COLOR}\]\w\[\e[0m\] '

alias ls='ls -1 --group-directories-first --color=auto'
alias ll='ls -lah'
alias la='ls -A'
alias grep='grep --color=auto'
export PATH="$HOME/.local/bin:$PATH"
export EDITOR=nano
export VISUAL=nano

[ -f ~/.config/theme-colors.sh ] && source ~/.config/theme-colors.sh

[ -f /usr/share/fzf/key-bindings.bash ] && source /usr/share/fzf/key-bindings.bash
[ -f /usr/share/fzf/completion.bash ]   && source /usr/share/fzf/completion.bash

# f: fuzzy-find a file under the current dir and open it in nano.
# Optional arg pre-fills the query, e.g. `f bashrc`.
f() {
    local file
    file="$(fd --type f --hidden --exclude .git 2>/dev/null \
        | fzf --height=40% --reverse --query="$1")" \
        && [ -n "$file" ] && nano -- "$file"
}

# fcd: fuzzy-find a directory under the current dir and cd into it.
fcd() {
    local dir
    dir="$(fd --type d --hidden --exclude .git 2>/dev/null \
        | fzf --height=40% --reverse --query="$1")" \
        && [ -n "$dir" ] && builtin cd -- "$dir"
}

y() {
    local tmp_cwd tmp_file choice cwd
    tmp_cwd="$(mktemp -t yazi-cwd.XXXXXX)"
    tmp_file="$(mktemp -t yazi-file.XXXXXX)"
    yazi "$@" --cwd-file="$tmp_cwd" --chooser-file="$tmp_file"
    if choice="$(cat -- "$tmp_file")" && [ -n "$choice" ]; then
        builtin cd -- "$(dirname "$choice")"
    elif cwd="$(cat -- "$tmp_cwd")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp_cwd" "$tmp_file"
}

# Ctrl+F: fuzzy-find a file and insert its path at the cursor.
_fzf_chooser_fn() {
    local choice

    choice="$(
        fd --type f --hidden --exclude .git 2>/dev/null \
        | fzf --height=40% --reverse < /dev/tty
    )"

    if [ -n "$choice" ]; then
        READLINE_LINE="${READLINE_LINE:0:READLINE_POINT}${choice}${READLINE_LINE:READLINE_POINT}"
        READLINE_POINT=$(( READLINE_POINT + ${#choice} ))
    fi
}

_yazi_chooser_fn() {
    local tmp_cwd tmp_file choice cwd
    tmp_cwd="$(mktemp -t yazi-cwd.XXXXXX)"
    tmp_file="$(mktemp -t yazi-file.XXXXXX)"
    YAZI_PICKER=1 YAZI_CHOOSER_FILE="$tmp_file" yazi --cwd-file="$tmp_cwd" --chooser-file="$tmp_file" < /dev/tty
    if choice="$(cat -- "$tmp_file")" && [ -n "$choice" ]; then
        READLINE_LINE="${READLINE_LINE:0:READLINE_POINT}${choice}${READLINE_LINE:READLINE_POINT}"
        READLINE_POINT=$(( READLINE_POINT + ${#choice} ))
    elif cwd="$(cat -- "$tmp_cwd")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp_cwd" "$tmp_file"
}

# yazi cd: browse and on quit cd into selected dir.
_yazi_cd_fn() {
    local tmp_cwd tmp_file choice cwd

    tmp_cwd="$(mktemp -t yazi-cwd.XXXXXX)"
    tmp_file="$(mktemp -t yazi-file.XXXXXX)"

    yazi --cwd-file="$tmp_cwd" --chooser-file="$tmp_file" < /dev/tty

    if choice="$(cat -- "$tmp_file")" && [ -n "$choice" ]; then
        builtin cd -- "$(dirname "$choice")"
    elif cwd="$(cat -- "$tmp_cwd")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi

    rm -f -- "$tmp_cwd" "$tmp_file"

    READLINE_LINE=
    READLINE_POINT=0
    printf '\n'
}

bind -x '"\C-y": _yazi_chooser_fn'  # Ctrl+Y — yazi picker (insert path)
bind '"\ey":"y\n"'

bind -x '"\C-f": _fzf_chooser_fn'   # Ctrl+F — fzf picker (insert path)
bind '"\ef":"fcd\n"'               # Alt+F — fuzzy cd into directory
