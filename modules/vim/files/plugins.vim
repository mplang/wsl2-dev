" wsl2-dev:vim -- the plugin list (vim-plug), sourced by vimrc.vim. The
" installers also run :PlugInstall with just this file. Updated by
" modules/vim/install.sh; edits here are lost: add your own plugins to
" ~/.config/wsl2-dev/vim/plugins.local.vim instead.

set nocompatible
let s:dir = (empty($XDG_CONFIG_HOME) ? expand('~/.config') : $XDG_CONFIG_HOME) . '/wsl2-dev'
" Icons and powerline symbols need a Nerd Font (WSL2DEV_ICONS=1; see README)
let s:icons = $WSL2DEV_ICONS ==# '1'

" ============================================================
" PLUGINS (vim-plug: :PlugUpdate, :PlugClean)
" ============================================================

let s:plug = expand('~/.vim/autoload/plug.vim')
if !filereadable(s:plug)
    silent execute '!curl -fsLo ' . shellescape(s:plug) . ' --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin()
Plug 'tpope/vim-fugitive'                " :Git, \gd
Plug 'airblade/vim-gitgutter'            " changed lines in the margin
Plug 'tpope/vim-surround'                " cs"' ds( ysiw]
Plug 'tpope/vim-commentary'              " gcc, gc<motion>
Plug 'preservim/nerdtree'                " \e
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'                  " Ctrl-P, \b, \/
Plug 'christoomey/vim-tmux-navigator'    " Ctrl-H/J/K/L across splits (and tmux panes)
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'gruvbox-community/gruvbox'
for s:f in glob(s:dir . '/*/vim-plugins.vim', 0, 1) + [s:dir . '/vim/plugins.local.vim']
    if filereadable(s:f)
        execute 'source' fnameescape(s:f)
    endif
endfor
if s:icons
    Plug 'ryanoasis/vim-devicons'        " must load last
endif
call plug#end()                          " also turns on filetype plugins and syntax
