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
