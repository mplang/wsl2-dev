#!/usr/bin/env bash
# install.sh -- node-nvm: node versions with nvm, switched per project by
# direnv
#
#   ./install.sh              install or update (and install the latest LTS node)
#   ./install.sh --dry-run    show what would change
#   ./install.sh --uninstall  remove it
#
# Installs nvm (to ~/.nvm) and direnv (apt), adds `use nvm` for direnv, and
# hooks ~/.config/wsl2-dev/node-nvm/shell.sh into ~/.bashrc and ~/.zshrc,
# whichever exist. See README.md.

MODULE=node-nvm
source "$(dirname "$0")/../../lib/common.sh"
parse_args "$@"
require_wsl

export NVM_DIR=${NVM_DIR:-$HOME/.nvm}
DIRENV_LIB=${XDG_CONFIG_HOME:-$HOME/.config}/direnv/lib/wsl2-dev-nvm.sh
HOOK='[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/wsl2-dev/node-nvm/shell.sh" ] && . "${XDG_CONFIG_HOME:-$HOME/.config}/wsl2-dev/node-nvm/shell.sh"'
mapfile -t RCS < <(shell_rcs)

if ((UNINSTALL)); then
    say "Removing $MODULE:"
    for rc in "${RCS[@]}"; do remove_hook "$rc" "#"; done
    remove_file "$CONFIG_DIR/shell.sh"
    remove_file "$CONFIG_DIR/direnv-hook.sh"
    remove_dir "$CONFIG_DIR"
    remove_file "$DIRENV_LIB"
    say "Done. nvm and its node versions stay in $(pretty "$NVM_DIR") (rm -rf it to delete them)."
    exit 0
fi

check_free "$CONFIG_DIR/shell.sh" "$CONFIG_DIR/direnv-hook.sh" "$DIRENV_LIB"
say "Installing $MODULE:"
apt_install direnv curl git

if [[ -s $NVM_DIR/nvm.sh ]]; then
    say "  nvm is in $(pretty "$NVM_DIR")"
else
    # The latest release; PROFILE=/dev/null stops the installer editing rc files
    tag=$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p')
    [[ -n $tag ]] || die "couldn't find nvm's latest release on GitHub"
    step "install nvm $tag to $(pretty "$NVM_DIR")" \
        sh -c 'curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$1/install.sh" | PROFILE=/dev/null bash >/dev/null' _ "$tag"
fi

if ((DRY_RUN)); then
    say "  would install the latest LTS node with nvm (if none is installed)"
elif compgen -G "$NVM_DIR/versions/node/v*" >/dev/null; then
    say "  node versions installed: $(cd "$NVM_DIR/versions/node" && echo v* | tr ' ' ',')"
else
    say "  installing the latest LTS node with nvm..."
    # shellcheck disable=SC1091
    bash -c '. "$NVM_DIR/nvm.sh" && nvm install --lts >/dev/null && nvm alias default "lts/*" >/dev/null' \
        && say "  installed node $(cd "$NVM_DIR/versions/node" && echo v*)" \
        || say "  nvm couldn't install node; open a new terminal and run: nvm install --lts"
fi

install_file "$MODULE_DIR/files/shell.sh" "$CONFIG_DIR/shell.sh" 644
install_file "$MODULE_DIR/files/direnv-hook.sh" "$CONFIG_DIR/direnv-hook.sh" 644
install_file "$MODULE_DIR/files/direnv-nvm.sh" "$DIRENV_LIB" 644
for rc in "${RCS[@]}"; do add_hook "$rc" "#" "$HOOK"; done
((${#RCS[@]})) || say "  no ~/.bashrc or ~/.zshrc found; source $(pretty "$CONFIG_DIR/shell.sh") from your shell's startup file"

say "Done. Open a new terminal: node --version. In a project: echo 22 > .nvmrc; echo 'use nvm' > .envrc; direnv allow"
