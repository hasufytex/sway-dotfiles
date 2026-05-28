# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS

# Completion
autoload -Uz compinit && compinit

# Better prompt
PROMPT='%F{blue}%~%f '

# Aliases
alias ls='ls --color=auto'
alias ll='ls -lah'
alias la='ls -A'
alias grep='grep --color=auto'
export PATH="$HOME/.local/bin:$PATH"

# Theme-aware env (BAT_THEME, FZF_DEFAULT_OPTS) — written by toggle_theme.sh
[ -f ~/.config/theme-colors.sh ] && source ~/.config/theme-colors.sh

# fzf shell integration (Ctrl-T, Ctrl-R, Alt-C)
[ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh
[ -f /usr/share/fzf/completions.zsh ] && source /usr/share/fzf/completions.zsh
