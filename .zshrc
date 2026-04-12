#instant prompt
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
	source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

#oh my zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(
	git
	z
	sudo
	colored-man-pages
	command-not-found
	history-substring-search
	zsh-autosuggestions
	zsh-syntax-highlighting
)
source $ZSH/oh-my-zsh.sh

#alias and functions
[[ -f ~/.config/bashrc/alias ]] && source ~/.config/bashrc/alias
[[ -f ~/.config/bashrc/functions ]] && source ~/.config/bashrc/functions

#p10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

export PATH="$PATH:/home/josep/.local/bin"
#load super secret alias
[[ -f ~/.config/bashrc/super-secret ]] && source ~/.config/bashrc/super-secret
