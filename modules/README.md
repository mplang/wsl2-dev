# Modules

Every module is self-contained: install any subset, in any order, and remove
any one without affecting the others.

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

```zsh
# >>> wsl2-dev:fzf >>>
source ~/.config/wsl2-dev/fzf/fzf.zsh
# <<< wsl2-dev:fzf <<<
```

| Tool | Hook |
|------|------|
| zsh | a marked `source` line in `~/.zshrc` |
| tmux | a marked `source-file` line in `~/.tmux.conf` |
| vim | a marked `source` line in `~/.vimrc` |
| git | an `[include]` added with `git config --global --add include.path` |
| direnv | a marked `source_env` line in `~/.config/direnv/direnvrc` |

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
