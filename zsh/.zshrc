# Zsh config: history, completion, prompt, aliases, theme env, fzf.
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS

autoload -Uz compinit && compinit

PROMPT='%F{blue}%~%f '

alias ls='ls --color=auto'
alias ll='ls -lah'
alias la='ls -A'
alias grep='grep --color=auto'
export PATH="$HOME/.local/bin:$PATH"

[ -f ~/.config/theme-colors.sh ] && source ~/.config/theme-colors.sh

[ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh
[ -f /usr/share/fzf/completions.zsh ] && source /usr/share/fzf/completions.zsh

function y() {
    local tmp_cwd="$(mktemp -t "yazi-cwd.XXXXXX")"
    local tmp_file="$(mktemp -t "yazi-file.XXXXXX")"

    yazi "$@" --cwd-file="$tmp_cwd" --chooser-file="$tmp_file"

    if choice="$(cat -- "$tmp_file")" && [ -n "$choice" ]; then
        builtin cd -- "$(dirname "$choice")"
    elif cwd="$(cat -- "$tmp_cwd")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi

    rm -f -- "$tmp_cwd" "$tmp_file"
}
function _yazi_chooser_fn() {
	local tmp_cwd="$(mktemp -t "yazi-cwd.XXXXXX")"
	local tmp_file="$(mktemp -t "yazi-file.XXXXXX")"

	yazi "$@" --cwd-file="$tmp_cwd" --chooser-file="$tmp_file" < /dev/tty

	if choice="$(cat -- "$tmp_file")" && [ -n "$choice" ]; then
		LBUFFER+="${choice}"
	elif cwd="$(cat -- "$tmp_cwd")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi

	rm -f -- "$tmp_cwd" "$tmp_file"
	zle reset-prompt
}

zle -N _yazi_chooser_fn
bindkey '\ey' _yazi_chooser_fn
