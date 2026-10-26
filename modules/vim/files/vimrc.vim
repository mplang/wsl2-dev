" wsl2-dev:vim -- sourced at the top of ~/.vimrc, so your settings below it
" win. Updated by modules/vim/install.sh; edits here are lost.
"
" Other wsl2-dev modules (vim-coc, theme) add to it by dropping files into
" ~/.config/wsl2-dev/<module>/: vim-plugins.vim (Plug lines) and
" vim-config.vim (settings). Your own Plug lines go in
" ~/.config/wsl2-dev/vim/plugins.local.vim.

set nocompatible             " vim, not vi (also when started with -u)
let s:dir = (empty($XDG_CONFIG_HOME) ? expand('~/.config') : $XDG_CONFIG_HOME) . '/wsl2-dev'
" Icons and powerline symbols need a Nerd Font (WSL2DEV_ICONS=1; see README)
let s:icons = $WSL2DEV_ICONS ==# '1'

" Plugins: :PlugUpdate updates them, :PlugClean removes ones you dropped
execute 'source' fnameescape(s:dir . '/vim/plugins.vim')

" ============================================================
" GENERAL
" ============================================================

set encoding=utf-8
set hidden                       " switch buffers without saving first
set updatetime=300
set mouse=a
set autoread
set backspace=indent,eol,start
set timeoutlen=500
set noerrorbells novisualbell t_vb=

" Swap and undo files in one place; undo history survives closing a file
if !isdirectory($HOME . '/.vim/tmp')
    call mkdir($HOME . '/.vim/tmp', 'p')
endif
set directory=$HOME/.vim/tmp//,.
set undodir=$HOME/.vim/tmp//,.
set undofile
set nobackup nowritebackup

" Search: case-insensitive unless you type a capital
set ignorecase smartcase hlsearch incsearch

" Display
set number relativenumber
set signcolumn=yes
set laststatus=2
set scrolloff=5
set showmatch matchtime=2
set wildmenu
set lazyredraw
set wrap linebreak breakindent
let &showbreak = '>>> '

" Indentation: 4 spaces (filetype plugins may change it per language)
set expandtab smarttab shiftwidth=4 tabstop=4 autoindent smartindent

" Clipboard: yanks go to the system clipboard when vim has +clipboard
" (Ubuntu's vim-gtk3). unnamed is macOS's clipboard but Linux's primary
" selection; unnamedplus is Linux's clipboard, which WSLg syncs with Windows.
set clipboard=unnamed,unnamedplus

set spelllang=en_us

" ============================================================
" TERMINAL AND COLORS
" ============================================================

if has('termguicolors')
    set termguicolors
    " True color escape codes inside tmux (vim doesn't know tmux-256color)
    if exists('$TMUX')
        let &t_8f = "\<Esc>[38:2:%lu:%lu:%lum"
        let &t_8b = "\<Esc>[48:2:%lu:%lu:%lum"
    endif
endif

" Cursor: bar in insert mode, underline in replace mode, block otherwise
let &t_SI = "\<Esc>[6 q"
let &t_SR = "\<Esc>[4 q"
let &t_EI = "\<Esc>[2 q"

augroup wsl2dev_vim
    autocmd!
    autocmd ColorScheme * highlight Comment cterm=italic gui=italic
    autocmd FocusGained,BufEnter * checktime
    " Relative line numbers only in normal mode
    autocmd InsertEnter * set norelativenumber
    autocmd InsertLeave * set relativenumber
augroup END

set background=dark
silent! colorscheme gruvbox

" ============================================================
" PLUGIN SETTINGS
" ============================================================

let g:airline#extensions#tabline#enabled = 1          " buffers as tabs at the top
let g:airline#extensions#tabline#formatter = 'unique_tail'
let g:airline_powerline_fonts = s:icons

" ============================================================
" KEYS (leader is \, vim's default)
" ============================================================

" Files and buffers
nnoremap <C-p> :Files<CR>
nnoremap <leader>b :Buffers<CR>
nnoremap <leader>/ :Rg<Space>
nnoremap <leader>e :NERDTreeToggle<CR>
nnoremap <Tab> :bnext<CR>
nnoremap <S-Tab> :bprevious<CR>
nnoremap <leader>x :w <Bar> bprevious <Bar> bdelete #<CR>
nnoremap <leader>cd :cd %:p:h<CR>:pwd<CR>

" Editing
nnoremap <silent> <leader><CR> :nohlsearch<CR>
nnoremap <silent> <leader>s :setlocal spell!<CR>
nnoremap <silent> <leader>rw :let _s=@/<Bar>%s/\s\+$//e<Bar>let @/=_s<CR>
nnoremap <F9> :edit $MYVIMRC<CR>

" Git (fugitive): side-by-side diff; in a merge, take //2 (ours) or //3 (theirs)
nnoremap <leader>gd :Gdiffsplit!<CR>
nnoremap <leader>du :diffupdate<CR>
nnoremap <leader>g2 :diffget //2<CR>
nnoremap <leader>g3 :diffget //3<CR>

" :W saves a file you opened without permission, via sudo
command! W execute 'silent write !sudo tee ' . shellescape(@%, 1) . ' > /dev/null' | edit!

" ============================================================
" OTHER MODULES' SETTINGS (vim-coc, theme)
" ============================================================

for s:f in glob(s:dir . '/*/vim-config.vim', 0, 1)
    execute 'source' fnameescape(s:f)
endfor
