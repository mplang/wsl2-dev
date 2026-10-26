# wsl2-dev:cli-tools -- sourced by ~/.bashrc and ~/.zshrc
#
# Each part applies only if its tool is installed.

# --- lsd: ls with colors, git-aware columns and (optionally) icons ---
# Icons need a Nerd Font in your terminal (see this module's README). To show
# them, set WSL2DEV_ICONS=1 above the wsl2-dev block in your shell's rc file.
if command -v lsd >/dev/null 2>&1; then
    if [ "${WSL2DEV_ICONS:-0}" = 1 ]; then
        alias ls='lsd'
    else
        alias ls='lsd --icon=never'
    fi
    alias ll='ls -l'                  # long listing
    alias la='ls -lA'                 # ... including dotfiles
    alias lt='ls --tree --depth 2'    # two levels of tree
fi

# --- bat: cat with syntax highlighting, paging and git changes ---
if command -v bat >/dev/null 2>&1; then
    # man pages in color
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
    export MANROFFOPT='-c'
    # follow a log file with highlighting: battail app.log
    battail() { tail -f "$@" | bat --paging=never -l log; }
    # a command's --help in color: bathelp git commit
    bathelp() { "$@" --help 2>&1 | bat --plain --language=help; }
fi
