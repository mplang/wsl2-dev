# fzf

[fzf](https://github.com/junegunn/fzf) turns any list into something you can
search by typing a few letters. This module sets it up for files, history
and directories, in bash and zsh, and in zsh replaces the Tab completion menu
with an fzf list ([fzf-tab](https://github.com/Aloxaf/fzf-tab)).

| Key | Does |
|-----|------|
| **Ctrl-T** | pick a file (with a preview) and paste its path into the command line |
| **Ctrl-R** | search your command history |
| **Alt-C** | pick a directory (with a tree preview) and `cd` into it |
| `**<Tab>` | fuzzy completion: `vim **<Tab>`, `cd src/**<Tab>`, `ssh **<Tab>`, `kill <Tab>` |
| **Tab** (zsh) | any completion menu as an fzf list; `<` and `>` switch between groups |
| **Ctrl-/** | in a list with a preview: move the preview or hide it |

It uses [ripgrep](https://github.com/BurntSushi/ripgrep) to list files when
it's installed (dotfiles included, `.gitignore`d files skipped), and
[bat](https://github.com/sharkdp/bat) and [eza](https://github.com/eza-community/eza)
for previews. All three come with the [`cli-tools`](../cli-tools/) module;
without them fzf still works, with plainer listings and no previews.

## Install

```bash
./install.sh --dry-run    # see what it would do
./install.sh
```

It installs `fzf` with apt (asking before it uses `sudo`), adds a marked
block to `~/.bashrc` and `~/.zshrc` (whichever exist) that loads
`~/.config/wsl2-dev/fzf/shell.sh`, and for zsh also clones fzf-tab to
`~/.local/share/wsl2-dev/fzf-tab` and loads it. Running the installer again
updates fzf-tab. Open a new terminal afterwards.

**Check:** press Ctrl-R and type part of an earlier command; in zsh, type
`cd ` and press Tab.

### Your own options

Settings in your rc file **above** the `wsl2-dev:fzf` block are kept:
`FZF_DEFAULT_OPTS` is extended, not replaced. To change something this
module sets, put it **below** the block. For example, to include
`.gitignore`d files in Ctrl-T (but still skip `node_modules`):

```bash
export FZF_CTRL_T_COMMAND="rg --files --hidden --follow --no-ignore --glob '!.git/' --glob '!**/node_modules/**'"
```

### By hand

```bash
sudo apt install fzf
git clone --depth=1 https://github.com/Aloxaf/fzf-tab ~/.local/share/wsl2-dev/fzf-tab   # zsh only
```

Then add the contents of `files/shell.sh` to your `~/.bashrc` or `~/.zshrc`,
and for zsh also `files/fzf-tab.zsh`.

## Remove

```bash
./install.sh --uninstall
sudo apt remove fzf        # optional
```

## Notes

- **fzf versions**: fzf 0.48 and later set up their key bindings themselves
  (`fzf --zsh`, `fzf --bash`); Ubuntu 26.04 has 0.67. Older Ubuntu releases
  ship them as scripts in `/usr/share/doc/fzf/examples/`, which this module
  loads instead.
- **oh-my-zsh's `fzf` plugin** does the same key-binding setup; you don't
  need both.
- **fzf-tab and other completion menus**: fzf-tab sets
  `zstyle ':completion:*' menu no`, which it needs to work well.
