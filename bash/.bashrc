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

[ -f ~/.config/theme-colors.sh ] && source ~/.config/theme-colors.sh

[ -f /usr/share/fzf/key-bindings.bash ] && source /usr/share/fzf/key-bindings.bash
[ -f /usr/share/fzf/completion.bash ]   && source /usr/share/fzf/completion.bash

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

_yazi_chooser_fn() {
    local tmp_cwd tmp_file choice cwd
    tmp_cwd="$(mktemp -t yazi-cwd.XXXXXX)"
    tmp_file="$(mktemp -t yazi-file.XXXXXX)"
    yazi --cwd-file="$tmp_cwd" --chooser-file="$tmp_file" < /dev/tty
    if choice="$(cat -- "$tmp_file")" && [ -n "$choice" ]; then
        READLINE_LINE="${READLINE_LINE:0:READLINE_POINT}${choice}${READLINE_LINE:READLINE_POINT}"
        READLINE_POINT=$(( READLINE_POINT + ${#choice} ))
    elif cwd="$(cat -- "$tmp_cwd")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp_cwd" "$tmp_file"
}
bind -x '"\ey": _yazi_chooser_fn'
