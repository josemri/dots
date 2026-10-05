# Alias y funciones compartidos
[[ -f ~/.config/bashrc/alias ]] && source ~/.config/bashrc/alias
[[ -f ~/.config/bashrc/functions ]] && source ~/.config/bashrc/functions
[[ -f ~/.config/bashrc/super-secret ]] && source ~/.config/bashrc/super-secret

# opencode
export PATH="/home/josep/.opencode/bin:$PATH"

# Historial
export HISTCONTROL=ignoreboth:erasedups
export HISTSIZE=10000
export HISTFILESIZE=20000
shopt -s histappend

# Autocompletado más completo
if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias diff='diff --color=auto'

eval "$(zoxide init bash)"

git_prompt() {
  git rev-parse --is-inside-work-tree &>/dev/null || return
  local s o=() n
  s=$(git status -sb 2>/dev/null)
  [[ $s == *"[ahead "* ]] && n=${s#*[ahead } && ((n=${n%%\]*})) && o+=("↑$n")
  [[ $s == *"[behind "* ]] && n=${s#*[behind } && ((n=${n%%\]*})) && o+=("↓$n")
  n=$(grep -cE '^(M|A|D|R|C)' <<<"$s") && ((n)) && o+=("+$n")
  n=$(grep -c '^.[MD]' <<<"$s") && ((n)) && o+=("!$n")
  n=$(grep -c '^\?\?' <<<"$s") && ((n)) && o+=("?${n}")
  n=$(git stash list 2>/dev/null | wc -l) && ((n)) && o+=("*$n")
  ((${#o[@]})) && printf '\001\e[0m\002%s\001\e[0m\002' "${o[*]}"
}

PROMPT_DIRTRIM=2

PS1=' \[\e[36m\]\w\[\e[0m\] $(git_prompt) \[\e[35m\]>\[\e[0m\] '
