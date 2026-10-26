#!/usr/bin/env bash
# install.sh -- ssh-agent: one SSH agent for every shell, via keychain
#
#   ./install.sh              install or update
#   ./install.sh --dry-run    show what would change
#   ./install.sh --uninstall  remove it
#
# Installs keychain (apt), and hooks
# ~/.config/wsl2-dev/ssh-agent/shell.sh into ~/.bashrc and ~/.zshrc,
# whichever exist. See README.md.

MODULE=ssh-agent
source "$(dirname "$0")/../../lib/common.sh"
parse_args "$@"
require_wsl

HOOK='[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/wsl2-dev/ssh-agent/shell.sh" ] && . "${XDG_CONFIG_HOME:-$HOME/.config}/wsl2-dev/ssh-agent/shell.sh"'
mapfile -t RCS < <(shell_rcs)

if ((UNINSTALL)); then
    say "Removing $MODULE:"
    for rc in "${RCS[@]}"; do remove_hook "$rc" "#"; done
    remove_file "$CONFIG_DIR/shell.sh"
    remove_dir "$CONFIG_DIR"
    say "Done. The agent keeps running until WSL shuts down (or: keychain --stop mine)."
    say "keychain itself is still installed (sudo apt remove keychain)."
    exit 0
fi

check_free "$CONFIG_DIR/shell.sh"
say "Installing $MODULE:"
apt_install keychain
install_file "$MODULE_DIR/files/shell.sh" "$CONFIG_DIR/shell.sh" 644
if ((${#RCS[@]})); then
    for rc in "${RCS[@]}"; do add_hook "$rc" "#" "$HOOK"; done
else
    say "  no ~/.bashrc or ~/.zshrc found; source $(pretty "$CONFIG_DIR/shell.sh") from your shell's startup file"
fi
if ! ls "$HOME"/.ssh/id_*.pub >/dev/null 2>&1; then
    say "Note: no SSH keys in ~/.ssh yet. Create one with: ssh-keygen -t ed25519"
fi
say "Done. Open a new terminal: keychain asks for your key's passphrase once."
