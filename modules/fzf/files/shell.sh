# wsl2-dev:fzf -- sourced by ~/.bashrc and ~/.zshrc
#
# Key bindings:  Ctrl-T  paste the path of a file you pick
#                Ctrl-R  search command history
#                Alt-C   cd into a directory you pick
# and **<Tab> completion: e.g. vim **<Tab>, cd src/**<Tab>, kill <Tab>

command -v fzf >/dev/null 2>&1 || return 0

# Files: ripgrep is fast, includes dotfiles, and skips what .gitignore lists
if command -v rg >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND="rg --files --hidden --follow --glob '!.git/'"
    export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
fi

# A compact list under the prompt instead of a full-screen one
export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:+$FZF_DEFAULT_OPTS }--height=40% --layout=reverse --border"

# Previews (Ctrl-/ moves or hides them): files with bat, directories as a tree
if command -v bat >/dev/null 2>&1; then
    export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :300 {}' --bind 'ctrl-/:change-preview-window(down|hidden|)'"
fi
if command -v eza >/dev/null 2>&1; then
    export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --color=always {}' --bind 'ctrl-/:change-preview-window(down|hidden|)'"
fi

# Key bindings and completion: built into fzf 0.48+; older Debian/Ubuntu
# packages ship them as scripts instead
if [ -n "${ZSH_VERSION:-}" ]; then _wsl2dev_sh=zsh; else _wsl2dev_sh=bash; fi
if fzf --"$_wsl2dev_sh" >/dev/null 2>&1; then
    eval "$(fzf --"$_wsl2dev_sh")"
else
    for _wsl2dev_f in key-bindings completion; do
        _wsl2dev_f=/usr/share/doc/fzf/examples/$_wsl2dev_f.$_wsl2dev_sh
        [ -r "$_wsl2dev_f" ] && . "$_wsl2dev_f"
    done
fi
unset _wsl2dev_sh _wsl2dev_f
