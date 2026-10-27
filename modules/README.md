# Modules

Every module is self-contained: install any subset, in any order, and remove
any one without affecting the others. The one exception is `vim-coc`, which
builds on `vim`: install `vim` first, and removing `vim` leaves `vim-coc`'s
files unused.

## Layout

```
modules/<name>/
├── README.md      what it does, why, manual install and removal
├── install.sh     installs or removes the module
└── files/         what gets installed (config snippets, scripts)
```

## How a Module Hooks In

Modules never overwrite your own config files. Each one installs its files
under `~/.config/wsl2-dev/<name>/` (scripts go to `~/.local/bin/`) and, where
a tool has no drop-in directory of its own, adds **one** line to your config
between markers:

```bash
# >>> wsl2-dev:cli-tools >>>
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/wsl2-dev/cli-tools/shell.sh" ] && . "${XDG_CONFIG_HOME:-$HOME/.config}/wsl2-dev/cli-tools/shell.sh"
# <<< wsl2-dev:cli-tools <<<
```

| Tool | Hook |
|------|------|
| bash, zsh | a marked line in `~/.bashrc` / `~/.zshrc` that loads the module's file |
| tmux | a marked `source-file` line at the top of `~/.tmux.conf` (and one at the end for plugins) |
| vim | a marked `source` line at the top of `~/.vimrc` |
| git | a marked `[include]` at the top of `~/.gitconfig` |
| direnv | a file in `~/.config/direnv/lib/` (direnv loads them all) |

Hooks at the **top** of a file (oh-my-zsh, tmux, vim, git) load the module
first, so your own settings below them win.

To remove a module by hand, delete its marked block and its
`~/.config/wsl2-dev/<name>/` folder.

Some modules extend another one by dropping files into their own folder,
which the other module loads if they exist:

| File | Loaded by | Used by |
|------|-----------|---------|
| `~/.config/wsl2-dev/*/vim-plugins.vim` | `vim`, inside `plug#begin()` | `vim-coc`, `theme` |
| `~/.config/wsl2-dev/*/vim-config.vim` | `vim`, at the end | `vim-coc`, `theme` |
| `~/.config/wsl2-dev/*/tmux-plugins.conf` | `tmux`, before TPM starts | `vim` |

## `install.sh`

Every module's script works the same way:

```bash
./install.sh              # install, or update an existing install
./install.sh --dry-run    # show what it would do; change nothing
./install.sh --uninstall  # remove the module's files and hooks
```

- **Idempotent**: running it twice changes nothing the second time.
- **Backs up** any file it edits, once, as `<file>.wsl2-dev.bak`.
- **Asks before `sudo`**: packages are listed, then installed with apt.
- **Checks prerequisites** and stops with a clear message if one is missing
  (e.g. `vim-coc` without `vim`).
