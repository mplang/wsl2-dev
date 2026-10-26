#!/usr/bin/env bash
# install.sh -- vim: a vim config and plugin set
#
#   ./install.sh              install or update (and install the plugins)
#   ./install.sh --dry-run    show what would change
#   ./install.sh --uninstall  remove it
#
# Installs vim (apt), hooks ~/.config/wsl2-dev/vim/vimrc.vim into the top of
# ~/.vimrc (your settings below it win), and installs the plugins with
# vim-plug. With the tmux module, also adds vim-tmux-navigator to tmux.
# See README.md.

MODULE=vim
source "$(dirname "$0")/../../lib/common.sh"
parse_args "$@"
require_wsl

# vim reads ~/.vimrc, or ~/.vim/vimrc when that doesn't exist
VIMRC=$HOME/.vimrc
[[ ! -e $VIMRC && -e $HOME/.vim/vimrc ]] && VIMRC=$HOME/.vim/vimrc
PLUG=$HOME/.vim/autoload/plug.vim
LOCAL=$CONFIG_DIR/plugins.local.vim
HOOK="source $(pretty "$CONFIG_DIR")/vimrc.vim"

if ((UNINSTALL)); then
    say "Removing $MODULE:"
    remove_hook "$VIMRC" '"'
    remove_file "$CONFIG_DIR/vimrc.vim"
    remove_file "$CONFIG_DIR/plugins.vim"
    remove_file "$CONFIG_DIR/tmux-plugins.conf"
    [[ -e $LOCAL ]] && say "  keeping $(pretty "$LOCAL") (your plugins; delete it if you like)"
    remove_dir "$CONFIG_DIR"
    say "Done. The plugins stay in ~/.vim/plugged and vim-plug in ~/.vim/autoload (delete them if you like)."
    exit 0
fi

check_free "$CONFIG_DIR/vimrc.vim" "$CONFIG_DIR/plugins.vim" "$CONFIG_DIR/tmux-plugins.conf"
say "Installing $MODULE:"
apt_install vim git curl
install_file "$MODULE_DIR/files/vimrc.vim" "$CONFIG_DIR/vimrc.vim" 644
install_file "$MODULE_DIR/files/plugins.vim" "$CONFIG_DIR/plugins.vim" 644
install_file "$MODULE_DIR/files/tmux-plugins.conf" "$CONFIG_DIR/tmux-plugins.conf" 644
[[ -e $LOCAL ]] || step "create $(pretty "$LOCAL") for your own plugins" cp "$MODULE_DIR/files/plugins.local.vim" "$LOCAL"

# Two plug#begin() blocks don't mix: the second replaces the first's list
if [[ -e $VIMRC ]] && _strip_block "$VIMRC" '"' | grep -q '^[^"]*plug#begin'; then
    say "Note: $(pretty "$VIMRC") has its own plug#begin()/plug#end(). Move its Plug lines into"
    say "      $(pretty "$LOCAL") and delete that block, or its plugins won't load."
fi
HOOK_POSITION=top add_hook "$VIMRC" '"' "$HOOK"

if [[ -e $PLUG ]]; then
    say "  vim-plug is in $(pretty "$PLUG")"
else
    step "download vim-plug to $(pretty "$PLUG")" \
        curl -fsSLo "$PLUG" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi
vim_plug_install vim-fugitive fzf.vim vim-airline gruvbox

say "Done. Open vim and try Ctrl-P (files), \\e (file tree), gcc (comment a line)."
[[ -e $HOME/.config/wsl2-dev/tmux/plugins.conf ]] &&
    say "With tmux: press Ctrl-Space then I (capital i) to install vim-tmux-navigator in tmux."
[[ $(vim --version) == *+clipboard* ]] ||
    say "Note: this vim can't use the Windows clipboard; sudo apt install vim-gtk3 adds that (see README.md)."
exit 0
