#!/usr/bin/env bash
# install.sh -- theme: one command to switch the colors of the shell, fzf,
# tmux, vim, Windows Terminal and (optionally) Windows
#
#   ./install.sh              install or update
#   ./install.sh --dry-run    show what would change
#   ./install.sh --uninstall  remove it
#
# Installs the `theme` command to ~/.local/bin, the themes to
# ~/.config/wsl2-dev/theme/, and hooks shell.sh into ~/.bashrc and ~/.zshrc
# (whichever exist). Changes nothing in Windows until you run `theme NAME`.
# See README.md.

MODULE=theme
source "$(dirname "$0")/../../lib/common.sh"
parse_args "$@"
require_wsl

STATE_DIR=${XDG_STATE_HOME:-$HOME/.local/state}/wsl2-dev/theme
THEMES=(gruvbox tomorrow-night modus-vivendi)
STATIC=(ls_colors windows.py shell.sh vim-plugins.vim vim-config.vim)
GENERATED=(env.sh fzfrc tmux.conf)
HOOK='[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/wsl2-dev/theme/shell.sh" ] && . "${XDG_CONFIG_HOME:-$HOME/.config}/wsl2-dev/theme/shell.sh"'
mapfile -t RCS < <(shell_rcs)

if ((UNINSTALL)); then
    say "Removing $MODULE:"
    for rc in "${RCS[@]}"; do remove_hook "$rc" "#"; done
    remove_file "$BIN_DIR/theme"
    for f in "${STATIC[@]}"; do remove_file "$CONFIG_DIR/$f"; done
    for t in "${THEMES[@]}"; do remove_file "$CONFIG_DIR/themes/$t.theme"; done
    remove_dir "$CONFIG_DIR/themes"
    # fzfrc can't carry a tag (fzf reads it as options); it's ours by location
    for f in "${GENERATED[@]}"; do
        [[ -e $CONFIG_DIR/$f ]] && step "remove $(pretty "$CONFIG_DIR/$f")" rm -f "$CONFIG_DIR/$f"
    done
    [[ -d $CONFIG_DIR/my-themes ]] && say "  keeping $(pretty "$CONFIG_DIR/my-themes") (your themes)"
    remove_dir "$CONFIG_DIR"
    [[ -e $STATE_DIR/current ]] && step "forget the current theme" rm -f "$STATE_DIR/current"
    [[ -d $STATE_DIR/windows-backup ]] &&
        say "  keeping $(pretty "$STATE_DIR/windows-backup") (double-click its .reg files in Windows to restore your colors)"
    say "Done. Windows Terminal keeps its current color scheme; pick another in its settings."
    exit 0
fi

check_free "$BIN_DIR/theme" "${STATIC[@]/#/$CONFIG_DIR/}" "${THEMES[@]/#/$CONFIG_DIR/themes/}"
say "Installing $MODULE:"
apt_install python3
install_file "$MODULE_DIR/files/bin/theme" "$BIN_DIR/theme" 755
for f in "${STATIC[@]}"; do install_file "$MODULE_DIR/files/$f" "$CONFIG_DIR/$f" 644; done
for t in "${THEMES[@]}"; do install_file "$MODULE_DIR/files/themes/$t.theme" "$CONFIG_DIR/themes/$t.theme" 644; done
for rc in "${RCS[@]}"; do add_hook "$rc" "#" "$HOOK"; done
((${#RCS[@]})) || say "  no ~/.bashrc or ~/.zshrc found; source $(pretty "$CONFIG_DIR/shell.sh") from your shell's startup file"

# Render the current theme (gruvbox the first time) for the shell, fzf, tmux
# and vim; Windows is left alone until you run `theme NAME`
step "render the current theme's colors" "$BIN_DIR/theme" --apply --no-terminal --quiet

[[ -e ${CONFIG_DIR%/*}/vim/vimrc.vim ]] && vim_plug_install vim-tomorrow-theme vim-colors-modus
say "Done. Open a new terminal, then: theme   (lists themes)   theme --dry-run gruvbox   theme gruvbox"
warn_path
