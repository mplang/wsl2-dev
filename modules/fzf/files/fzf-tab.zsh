# wsl2-dev:fzf -- sourced by ~/.zshrc
#
# fzf-tab: zsh's Tab completion menu becomes an fzf list you can search.
# https://github.com/Aloxaf/fzf-tab

_wsl2dev_fzf_tab=${XDG_DATA_HOME:-$HOME/.local/share}/wsl2-dev/fzf-tab/fzf-tab.plugin.zsh
if (( $+commands[fzf] )) && [[ -r $_wsl2dev_fzf_tab ]]; then
    # fzf-tab needs compinit; frameworks usually ran it already
    (( ${+_comps} )) || { autoload -Uz compinit && compinit; }
    source $_wsl2dev_fzf_tab

    # Let fzf-tab handle the menu, and show group names to switch between
    zstyle ':completion:*' menu no
    zstyle ':completion:*:descriptions' format '[%d]'
    zstyle ':fzf-tab:*' switch-group '<' '>'
    zstyle ':completion:*:git-checkout:*' sort false
    # Preview directories while completing cd
    if (( $+commands[eza] )); then
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
    else
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -1 --color=always $realpath'
    fi
fi
unset _wsl2dev_fzf_tab
