#!/usr/bin/env bash
# install.sh -- vim-coc: language-server completion in vim (CoC), with ALE
#
#   ./install.sh              install or update
#   ./install.sh --dry-run    show what would change
#   ./install.sh --uninstall  remove it
#
# Needs the vim module. Puts vim-plugins.vim and vim-config.vim in
# ~/.config/wsl2-dev/vim-coc/, where the vim module loads them; makes sure
# node is available; installs the plugins. See README.md.

MODULE=vim-coc
source "$(dirname "$0")/../../lib/common.sh"
parse_args "$@"
require_wsl

VIM_DIR=${CONFIG_DIR%/*}/vim
VIMRC=$HOME/.vimrc
[[ ! -e $VIMRC && -e $HOME/.vim/vimrc ]] && VIMRC=$HOME/.vim/vimrc
COC_SETTINGS=$HOME/.vim/coc-settings.json

if ((UNINSTALL)); then
    say "Removing $MODULE:"
    remove_file "$CONFIG_DIR/vim-plugins.vim"
    remove_file "$CONFIG_DIR/vim-config.vim"
    remove_dir "$CONFIG_DIR"
    say "Done. Run :PlugClean in vim to delete the plugins. Kept: $(pretty "$COC_SETTINGS") and"
    say "CoC's extensions in ~/.config/coc (delete them if you like)."
    exit 0
fi

[[ -e $VIM_DIR/vimrc.vim ]] || die "install the vim module first (modules/vim/install.sh)"
check_free "$CONFIG_DIR/vim-plugins.vim" "$CONFIG_DIR/vim-config.vim"
say "Installing $MODULE:"

# CoC runs on node: PATH, nvm, or apt's nodejs
if command -v node >/dev/null; then
    say "  node $(node --version) is on PATH"
elif compgen -G "$HOME/.nvm/versions/node/*/bin/node" >/dev/null; then
    say "  using node from nvm"
else
    apt_install nodejs
fi

install_file "$MODULE_DIR/files/vim-plugins.vim" "$CONFIG_DIR/vim-plugins.vim" 644
install_file "$MODULE_DIR/files/vim-config.vim" "$CONFIG_DIR/vim-config.vim" 644
# coc-settings.json is yours once it exists
[[ -e $COC_SETTINGS ]] && say "  keeping your $(pretty "$COC_SETTINGS")" ||
    step "create $(pretty "$COC_SETTINGS")" install -D -m 644 "$MODULE_DIR/files/coc-settings.json" "$COC_SETTINGS"

vim_plug_install coc.nvim ale
say "Done. The first time you open vim, CoC installs its language servers (a minute or so;"
say "watch with :CocInfo). Then try gd (go to definition) or K (docs) in a source file."
