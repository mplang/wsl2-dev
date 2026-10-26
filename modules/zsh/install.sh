#!/usr/bin/env bash
# install.sh -- zsh: install zsh and give it sensible defaults
#
#   ./install.sh              install or update
#   ./install.sh --dry-run    show what would change
#   ./install.sh --uninstall  remove it
#
# Installs zsh and zsh-autosuggestions (apt), hooks
# ~/.config/wsl2-dev/zsh/zsh.zsh into ~/.zshrc (creating it if needed), and
# offers to make zsh your default shell. See README.md.

MODULE=zsh
source "$(dirname "$0")/../../lib/common.sh"
parse_args "$@"
require_wsl

ZSHRC=${ZDOTDIR:-$HOME}/.zshrc
HOOK='[[ -f ${XDG_CONFIG_HOME:-$HOME/.config}/wsl2-dev/zsh/zsh.zsh ]] && source ${XDG_CONFIG_HOME:-$HOME/.config}/wsl2-dev/zsh/zsh.zsh'
login_shell=$(getent passwd "$USER" | cut -d: -f7)

if ((UNINSTALL)); then
    say "Removing $MODULE:"
    remove_hook "$ZSHRC" "#"
    remove_file "$CONFIG_DIR/zsh.zsh"
    remove_dir "$CONFIG_DIR"
    say "Done. zsh is still installed$([[ $login_shell == */zsh ]] && echo " and your default shell (back to bash: chsh -s /bin/bash)")."
    exit 0
fi

check_free "$CONFIG_DIR/zsh.zsh"
say "Installing $MODULE:"
apt_install zsh zsh-autosuggestions
install_file "$MODULE_DIR/files/zsh.zsh" "$CONFIG_DIR/zsh.zsh" 644
add_hook "$ZSHRC" "#" "$HOOK"

if [[ $login_shell == */zsh ]]; then
    say "  zsh is already your default shell"
elif ((DRY_RUN)); then
    say "  would offer to make zsh your default shell (now $login_shell)"
elif confirm "Make zsh your default shell? (now $login_shell)"; then
    step "make zsh the default shell" chsh -s "$(command -v zsh)"
else
    say "  keeping $login_shell; start zsh with: zsh   (default later: chsh -s $(command -v zsh || echo /usr/bin/zsh))"
fi
say "Done. Open a new terminal."
