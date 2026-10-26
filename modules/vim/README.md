# vim

A vim configuration and plugin set: fuzzy file finding, a file tree, git
integration, a status line, a good dark colorscheme, and settings that suit
a terminal on WSL. Language-server completion is a separate module,
[`vim-coc`](../vim-coc/).

| Plugin | What it gives you |
|--------|-------------------|
| [fzf.vim](https://github.com/junegunn/fzf.vim) | **Ctrl-P** find a file, **`\b`** switch buffer, **`\/`** search file contents (ripgrep) |
| [NERDTree](https://github.com/preservim/nerdtree) | **`\e`** file tree |
| [fugitive](https://github.com/tpope/vim-fugitive) | `:Git` anything; **`\gd`** side-by-side diff |
| [gitgutter](https://github.com/airblade/vim-gitgutter) | added/changed/removed lines in the margin |
| [surround](https://github.com/tpope/vim-surround) | `cs"'` change quotes, `ds(` delete parentheses, `ysiw]` wrap a word |
| [commentary](https://github.com/tpope/vim-commentary) | `gcc` comment a line, `gc` + motion |
| [airline](https://github.com/vim-airline/vim-airline) | status line, and open buffers as tabs along the top |
| [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) | **Ctrl-H/J/K/L** move between splits, and between vim and tmux panes |
| [gruvbox](https://github.com/gruvbox-community/gruvbox) | colorscheme |

Other keys (`\` is the leader, vim's default):

| Key | Does |
|-----|------|
| **Tab** / **Shift-Tab** | next / previous buffer |
| `\x` | save and close the buffer, keeping the window |
| `\<Enter>` | clear search highlighting |
| `\s` | spell checking on/off |
| `\rw` | remove trailing whitespace |
| `\cd` | `cd` to the current file's directory |
| `\g2` / `\g3` | in a merge conflict diff, take ours / theirs |
| **F9** | edit your vimrc |
| `:W` | save a file you opened without permission (sudo) |

Settings worth knowing: line numbers (relative in normal mode), 4-space
indents, case-insensitive search unless you type a capital, mouse on,
persistent undo, swap files kept in `~/.vim/tmp`, true color (also inside
tmux), and cursor shapes per mode.

## Install

```bash
./install.sh --dry-run    # see what it would do
./install.sh
```

It installs `vim`, `git` and `curl` with apt (asking before it uses `sudo`),
adds a marked line at the **top** of `~/.vimrc` (creating it if needed) that
loads `~/.config/wsl2-dev/vim/vimrc.vim`, downloads
[vim-plug](https://github.com/junegunn/vim-plug), and installs the plugins.
Running it again updates the config; `:PlugUpdate` in vim updates the
plugins.

**Check:** open vim in a project and press Ctrl-P.

### With tmux

With the [`tmux`](../tmux/) module installed, this module also adds
vim-tmux-navigator's tmux half, so Ctrl-H/J/K/L cross between vim splits and
tmux panes. Press Ctrl-Space then `I` once in tmux to install it. Ctrl-L
then moves right instead of clearing the screen; prefix Ctrl-L clears it.

### Your own settings and plugins

- **Settings**: in `~/.vimrc`, below the marked block. They win.
- **Plugins**: add `Plug '...'` lines to
  `~/.config/wsl2-dev/vim/plugins.local.vim` (created once, never changed by
  updates), then `:PlugInstall`. Don't add a second
  `plug#begin()`/`plug#end()` to `~/.vimrc`: it would replace this plugin
  list. The installer warns if it finds one.

Prefer different keys? Remap them in `~/.vimrc`, for example:

```vim
nnoremap ; :Files<CR>              " ; for files (it normally repeats f/t)
nnoremap <C-o> :NERDTreeToggle<CR> " (it normally jumps back)
```

### Icons and the Windows clipboard

- **Icons and powerline arrows** (devicons in NERDTree and airline) need a
  [Nerd Font](https://www.nerdfonts.com/) in Windows Terminal. Set
  `export WSL2DEV_ICONS=1` in your shell's rc file (the same switch the
  [`cli-tools`](../cli-tools/) module uses), open a new terminal, and run
  `:PlugInstall`.
- **Yanking to Windows**: Ubuntu's `vim` can't use the system clipboard.
  `sudo apt install vim-gtk3` is the same vim with clipboard support; with
  it, `y` copies to the Windows clipboard and `p` pastes from it (WSLg
  bridges the two). Without it, copy from tmux or the terminal instead.

### By hand

```bash
sudo apt install vim git curl
```

Add `source /path/to/files/vimrc.vim` at the top of `~/.vimrc`, then start
vim: it downloads vim-plug and installs the plugins.

## Remove

```bash
./install.sh --uninstall
rm -rf ~/.vim/plugged ~/.vim/autoload/plug.vim     # optional
```

The uninstaller keeps `plugins.local.vim`.
