#!/usr/bin/env bash
# install.sh -- oh-my-zsh: the zsh framework, with a small plugin set
#
#   ./install.sh              install or update
#   ./install.sh --p10k       ... with the powerlevel10k prompt
#   ./install.sh --dry-run    show what would change
#   ./install.sh --uninstall  remove it
#
# Clones oh-my-zsh to ~/.oh-my-zsh and hooks
# ~/.config/wsl2-dev/oh-my-zsh/oh-my-zsh.zsh into the top of ~/.zshrc.
# Your theme and plugin changes go in ~/.config/wsl2-dev/oh-my-zsh/local.zsh.
# See README.md.

MODULE=oh-my-zsh
P10K=0
module_option() { [[ $1 == --p10k ]] && P10K=1; }
source "$(dirname "$0")/../../lib/common.sh"
parse_args "$@"
require_wsl

ZSHRC=${ZDOTDIR:-$HOME}/.zshrc
OMZ=${ZSH:-$HOME/.oh-my-zsh}
P10K_DIR=${ZSH_CUSTOM:-$OMZ/custom}/themes/powerlevel10k
LOCAL=$CONFIG_DIR/local.zsh
HOOK='[[ -f ${XDG_CONFIG_HOME:-$HOME/.config}/wsl2-dev/oh-my-zsh/oh-my-zsh.zsh ]] && source ${XDG_CONFIG_HOME:-$HOME/.config}/wsl2-dev/oh-my-zsh/oh-my-zsh.zsh'

if ((UNINSTALL)); then
    say "Removing $MODULE:"
    remove_hook "$ZSHRC" "#"
    remove_file "$CONFIG_DIR/oh-my-zsh.zsh"
    [[ -e $LOCAL ]] && say "  keeping $(pretty "$LOCAL") (your settings; delete it if you like)"
    remove_dir "$CONFIG_DIR"
    say "Done. oh-my-zsh itself is still in $(pretty "$OMZ") (rm -rf it to delete)."
    exit 0
fi

require_cmd git zsh
check_free "$CONFIG_DIR/oh-my-zsh.zsh"
say "Installing $MODULE:"
if [[ -d $OMZ/.git ]]; then
    say "  oh-my-zsh is in $(pretty "$OMZ") (it updates itself)"
else
    [[ -e $OMZ ]] && die "$(pretty "$OMZ") exists but isn't an oh-my-zsh checkout; move it aside first"
    step "clone oh-my-zsh to $(pretty "$OMZ")" \
        git clone -q --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$OMZ"
fi
if ((P10K)); then
    if [[ -d $P10K_DIR ]]; then
        say "  powerlevel10k is in $(pretty "$P10K_DIR")"
    else
        step "clone powerlevel10k to $(pretty "$P10K_DIR")" \
            git clone -q --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
    fi
fi

install_file "$MODULE_DIR/files/oh-my-zsh.zsh" "$CONFIG_DIR/oh-my-zsh.zsh" 644
# local.zsh is the user's: create it once, never touch it again
if [[ ! -e $LOCAL ]]; then
    if ((P10K)); then
        step "create $(pretty "$LOCAL") (theme: powerlevel10k)" \
            sh -c '{ cat "$1"; printf "\nZSH_THEME=powerlevel10k/powerlevel10k\n"; } > "$2"' _ "$MODULE_DIR/files/local.zsh" "$LOCAL"
    else
        step "create $(pretty "$LOCAL") for your own settings" cp "$MODULE_DIR/files/local.zsh" "$LOCAL"
    fi
elif ((P10K)) && ! grep -q '^ZSH_THEME=powerlevel10k' "$LOCAL"; then
    say "  to use powerlevel10k, add to $(pretty "$LOCAL"): ZSH_THEME=powerlevel10k/powerlevel10k"
fi
HOOK_POSITION=top add_hook "$ZSHRC" "#" "$HOOK"

say "Done. Open a new terminal (or: exec zsh)."
((P10K)) && say "powerlevel10k's setup wizard starts on first use; it looks best with a Nerd Font (see README.md)."
command -v zsh >/dev/null && [[ $(getent passwd "$USER" | cut -d: -f7) != */zsh ]] &&
    say "Note: zsh isn't your default shell. The zsh module can set that up, or: chsh -s $(command -v zsh)"
exit 0
