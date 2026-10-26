#!/usr/bin/env bash
# install.sh -- windows-integration: open things in Windows, and use the
# Windows clipboard, from Linux
#
#   ./install.sh              install or update
#   ./install.sh --dry-run    show what would change
#   ./install.sh --uninstall  remove it
#
# Installs winopen, pbcopy and pbpaste to ~/.local/bin, and hooks
# ~/.config/wsl2-dev/windows-integration/shell.sh (BROWSER, the open alias)
# into ~/.bashrc and ~/.zshrc, whichever exist. See README.md.

MODULE=windows-integration
source "$(dirname "$0")/../../lib/common.sh"
parse_args "$@"
require_wsl

SCRIPTS=(winopen pbcopy pbpaste)
HOOK='[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/wsl2-dev/windows-integration/shell.sh" ] && . "${XDG_CONFIG_HOME:-$HOME/.config}/wsl2-dev/windows-integration/shell.sh"'
mapfile -t RCS < <(shell_rcs)

if ((UNINSTALL)); then
    say "Removing $MODULE:"
    for s in "${SCRIPTS[@]}"; do remove_file "$BIN_DIR/$s"; done
    for rc in "${RCS[@]}"; do remove_hook "$rc" "#"; done
    remove_file "$CONFIG_DIR/shell.sh"
    remove_dir "$CONFIG_DIR"
    say "Done. Open a new terminal to drop BROWSER and the open alias."
    exit 0
fi

check_free "${SCRIPTS[@]/#/$BIN_DIR/}" "$CONFIG_DIR/shell.sh"
say "Installing $MODULE:"
for s in "${SCRIPTS[@]}"; do install_file "$MODULE_DIR/files/bin/$s" "$BIN_DIR/$s" 755; done
install_file "$MODULE_DIR/files/shell.sh" "$CONFIG_DIR/shell.sh" 644
if ((${#RCS[@]})); then
    for rc in "${RCS[@]}"; do add_hook "$rc" "#" "$HOOK"; done
else
    say "  no ~/.bashrc or ~/.zshrc found; source $(pretty "$CONFIG_DIR/shell.sh") from your shell's startup file"
fi
say "Done. Open a new terminal, then try: winopen .   or   echo hi | pbcopy"
warn_path
