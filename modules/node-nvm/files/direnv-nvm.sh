# wsl2-dev:node-nvm -- loaded by direnv (from ~/.config/direnv/lib/).
#
# `use nvm` in a project's .envrc: switch to the node version in .nvmrc
# (or `use nvm 22`), installing it with nvm first if needed.

use_nvm() {
    export NVM_DIR=${NVM_DIR:-$HOME/.nvm}
    if [[ ! -s $NVM_DIR/nvm.sh ]]; then
        log_error "nvm isn't installed (the wsl2-dev node-nvm module installs it)"
        return 1
    fi
    watch_file .nvmrc
    # shellcheck disable=SC1091
    source "$NVM_DIR/nvm.sh" --no-use
    nvm use "$@" >/dev/null 2>&1 || { nvm install "$@" >&2 && nvm use "$@" >/dev/null; }
}
