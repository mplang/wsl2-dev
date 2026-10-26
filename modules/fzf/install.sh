#!/usr/bin/env bash
# install.sh -- fzf: fuzzy finding for files, history and directories, and
# (in zsh) an fzf Tab-completion menu
#
#   ./install.sh              install or update
#   ./install.sh --dry-run    show what would change
#   ./install.sh --uninstall  remove it
#
# Installs fzf (apt), hooks ~/.config/wsl2-dev/fzf/shell.sh into ~/.bashrc
# and ~/.zshrc (whichever exist), and for zsh clones fzf-tab to
# ~/.local/share/wsl2-dev/fzf-tab. See README.md.

MODULE=fzf
source "$(dirname "$0")/../../lib/common.sh"
parse_args "$@"
require_wsl

FZF_TAB=${XDG_DATA_HOME:-$HOME/.local/share}/wsl2-dev/fzf-tab
FZF_TAB_URL=https://github.com/Aloxaf/fzf-tab
ZSHRC=${ZDOTDIR:-$HOME}/.zshrc
D='${XDG_CONFIG_HOME:-$HOME/.config}/wsl2-dev/fzf'
SH_HOOK="[ -f \"$D/shell.sh\" ] && . \"$D/shell.sh\""
TAB_HOOK="[[ -f \"$D/fzf-tab.zsh\" ]] && source \"$D/fzf-tab.zsh\""
mapfile -t RCS < <(shell_rcs)

is_our_clone() { [[ $(git -C "$FZF_TAB" remote get-url origin 2>/dev/null) == "$FZF_TAB_URL" ]]; }

if ((UNINSTALL)); then
    say "Removing $MODULE:"
    for rc in "${RCS[@]}"; do remove_hook "$rc" "#"; done
    remove_file "$CONFIG_DIR/shell.sh"
    remove_file "$CONFIG_DIR/fzf-tab.zsh"
    remove_dir "$CONFIG_DIR"
    if is_our_clone; then
        step "remove $(pretty "$FZF_TAB")" rm -rf -- "$FZF_TAB"
        rmdir --ignore-fail-on-non-empty "${FZF_TAB%/*}" 2>/dev/null || true
    fi
    say "Done. fzf itself is still installed (sudo apt remove fzf)."
    exit 0
fi

check_free "$CONFIG_DIR/shell.sh" "$CONFIG_DIR/fzf-tab.zsh"
say "Installing $MODULE:"
apt_install fzf
install_file "$MODULE_DIR/files/shell.sh" "$CONFIG_DIR/shell.sh" 644
install_file "$MODULE_DIR/files/fzf-tab.zsh" "$CONFIG_DIR/fzf-tab.zsh" 644

if [[ -e $ZSHRC ]]; then
    require_cmd git
    if is_our_clone; then
        if ((DRY_RUN)); then
            say "  would update fzf-tab in $(pretty "$FZF_TAB") (git pull)"
        else
            before=$(git -C "$FZF_TAB" rev-parse HEAD)
            git -C "$FZF_TAB" pull -q --ff-only
            if [[ $(git -C "$FZF_TAB" rev-parse HEAD) == "$before" ]]; then
                say "  fzf-tab in $(pretty "$FZF_TAB") is up to date"
            else
                say "  updated fzf-tab in $(pretty "$FZF_TAB")"
            fi
        fi
    elif [[ -e $FZF_TAB ]]; then
        die "$(pretty "$FZF_TAB") exists but isn't a clone of $FZF_TAB_URL; move it aside first"
    else
        step "clone fzf-tab to $(pretty "$FZF_TAB")" git clone -q --depth=1 "$FZF_TAB_URL" "$FZF_TAB"
    fi
fi

for rc in "${RCS[@]}"; do
    if [[ $rc == "$ZSHRC" ]]; then
        add_hook "$rc" "#" "$SH_HOOK" "$TAB_HOOK"
    else
        add_hook "$rc" "#" "$SH_HOOK"
    fi
done
((${#RCS[@]})) || say "  no ~/.bashrc or ~/.zshrc found; source $(pretty "$CONFIG_DIR/shell.sh") from your shell's startup file"

say "Done. Open a new terminal, then try Ctrl-T, Ctrl-R, Alt-C$([[ -e $ZSHRC ]] && echo ", or cd <Tab> (zsh)")."
command -v rg >/dev/null || say "Note: with ripgrep (the cli-tools module) file search is faster and skips .gitignored files."
exit 0
