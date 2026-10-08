[[ $- == *i* ]] || return 0 2>/dev/null || exit 0 # only interactive shell

# prompt
git_prompt() {
	local l b n s=0 m=0 u=0 c=0 o=()
	while IFS= read -r l; do
		case ${l:0:2} in
			'##') b=${l:3};; '??') ((u++));; DD|AA|*U*) ((c++));;
			*) [[ ${l:0:1} != ' ' ]] && ((s++)); [[ ${l:1:1} != ' ' ]] && ((m++));;
		esac
	done < <(git status --porcelain=v1 -b 2>/dev/null)
	[[ $b == *'['* ]] && { n=${b#*\[}; n=${n%\]*}
	[[ $n == *ahead* ]] && b=${n#*ahead } && o+=("↑${b%%[!0-9]*}")
	[[ $n == *behind* ]] && o+=("↓${n##*behind }"); }
	((s)) && o+=("+$s"); ((m)) && o+=("!$m"); ((u)) && o+=("?$u"); ((c)) && o+=("✖$c")
	git rev-parse --verify -q refs/stash &>/dev/null && o+=("*")
	((${#o[@]})) && printf "\001\e[$((s||m||u||c?33:32))m\002%s\001\e[0m\002" "${o[*]}"
}
PROMPT_DIRTRIM=2
PS1=' \[\e]0;\u@\h: \w\a\]\[\e[36m\]\w\[\e[0m\] $(git_prompt)\[\e[35m\]>\[\e[0m\] '

# alias & funcs
[[ -f ~/.config/bashrc/alias ]] && source ~/.config/bashrc/alias
[[ -f ~/.config/bashrc/functions ]] && source ~/.config/bashrc/functions
[[ -f ~/.config/bashrc/super-secret ]] && source ~/.config/bashrc/super-secret

# Autocompletado
if [[ -f /usr/share/bash-completion/bash_completion ]]; then
	. /usr/share/bash-completion/bash_completion
elif [[ -f /etc/bash_completion ]]; then
	. /etc/bash_completion
fi

# historial
export HISTCONTROL=ignoreboth:erasedups
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTTIMEFORMAT='%F %T '
export HISTIGNORE='ls:la:cd:pwd:exit:clear'
shopt -s histappend
export EDITOR=nvim
export VISUAL=nvim

eval "$(zoxide init bash)" # zoxide
case ":$PATH:" in #opencode guard
	*":$HOME/.opencode/bin:"*) ;;
	*) export PATH="$HOME/.opencode/bin:$PATH" ;;
esac
