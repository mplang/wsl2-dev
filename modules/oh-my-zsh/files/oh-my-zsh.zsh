# wsl2-dev:oh-my-zsh -- sourced at the top of ~/.zshrc
#
# Loads oh-my-zsh with a small, useful plugin set. Change the theme or the
# plugins in ~/.config/wsl2-dev/oh-my-zsh/local.zsh, which is yours: updates
# never overwrite it.

export ZSH=${ZSH:-$HOME/.oh-my-zsh}
ZSH_THEME=robbyrussell
plugins=(
    git                       # aliases: gst = git status, gco = git checkout, ...
    history-substring-search  # Up/Down: history matching what you've typed
    colored-man-pages
    command-not-found         # suggests the package for an unknown command
    dirhistory                # Alt-Left/Right: back/forward through directories
)

[[ -r ${XDG_CONFIG_HOME:-$HOME/.config}/wsl2-dev/oh-my-zsh/local.zsh ]] &&
    source ${XDG_CONFIG_HOME:-$HOME/.config}/wsl2-dev/oh-my-zsh/local.zsh

source $ZSH/oh-my-zsh.sh

# oh-my-zsh's bracketed-paste-magic garbles multi-line pastes in tmux when
# zsh-autosuggestions is also loaded; plain bracketed paste works everywhere
zle -A .bracketed-paste bracketed-paste
