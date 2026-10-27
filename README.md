# wsl2-dev

Guides and small, independent tooling modules for developing on
[WSL2](https://learn.microsoft.com/windows/wsl/about) with Ubuntu.

Take what you want and skip the rest. No module requires another (except
`vim-coc`, which builds on `vim`), and none changes a tool you didn't
install a module for. For example, unless you install the `vim` module,
nothing here edits your `~/.vimrc` or adds vim plugins.

## Guides

| Guide | For |
|-------|-----|
| [Developing on WSL2 (Ubuntu)](guides/developer-guide.md) | Installing WSL2, the filesystem, Windows interop, VS Code, git and SSH, Node, Java and Python, GPUs, Docker (Desktop or Engine), backups and upgrades, troubleshooting, and notes for people coming from macOS; with pointers to the modules below |
| [Developing on WSL2 (Ubuntu), standalone](guides/developer-guide-standalone.md) | The same guide with no references to this repository, to share or copy on its own |

## Modules

Each module is a folder under [`modules/`](modules/) with a README (what it
does, why, how to install and remove it by hand) and an `install.sh` that
does the same for you. See [modules/README.md](modules/README.md) for how
they're put together.

| Module | What it does |
|--------|--------------|
| [`windows-integration`](modules/windows-integration/) | Open URLs, files and folders in Windows (`winopen`, `open`, `BROWSER`), and `pbcopy`/`pbpaste` for the Windows clipboard |
| [`ssh-agent`](modules/ssh-agent/) | One SSH agent for every shell (keychain): type your key's passphrase once per WSL session |
| [`cli-tools`](modules/cli-tools/) | bat, lsd, eza, ripgrep and glow, with `ls`/`ll`/`la`/`lt` aliases and colored man pages |
| [`zsh`](modules/zsh/) | zsh with large shared history, autosuggestions, better completion and keys; works with or without a framework |
| [`oh-my-zsh`](modules/oh-my-zsh/) | oh-my-zsh with a small plugin set, your own `local.zsh`, and optionally powerlevel10k |
| [`fzf`](modules/fzf/) | Fuzzy search for files (Ctrl-T), history (Ctrl-R) and directories (Alt-C) with previews; fzf-tab completion menus in zsh |
| [`git`](modules/git/) | WSL-friendly git settings (LF line endings, `zdiff3` conflicts, rebasing pulls, ...), VS Code as diff/merge tool, Windows' Git Credential Manager for HTTPS |
| [`tmux`](modules/tmux/) | tmux for Windows Terminal: `Ctrl-Space` prefix, mouse, copies to the Windows clipboard, a themeable status bar, plugins via TPM |
| [`vim`](modules/vim/) | A vim config and plugin set: fzf, NERDTree, fugitive, airline, gruvbox, and Ctrl-H/J/K/L across vim and tmux |
| [`vim-coc`](modules/vim-coc/) | Language servers in vim (CoC): completion, go to definition, rename, code actions; ALE fixers. Needs `vim` |
| [`python-uv`](modules/python-uv/) | Python projects with uv; direnv activates each project's `.venv` on `cd` (`layout uv`) |
| [`node-nvm`](modules/node-nvm/) | Node versions with nvm, without nvm's slow shell startup; direnv switches per project (`use nvm`) |
| [`theme`](modules/theme/) | One command to switch the colors of Windows Terminal, file listings, bat, fzf, tmux, vim and (optionally) Windows: Gruvbox, Tomorrow Night, Modus Vivendi |

## Quick Start

```bash
git clone https://github.com/mplang/wsl2-dev.git ~/wsl2-dev
cd ~/wsl2-dev/modules/windows-integration
./install.sh --dry-run        # see what it would change
./install.sh
```

Each installer asks before it uses `sudo`, never overwrites a file it
didn't create, backs up any file it edits, and undoes itself with
`--uninstall`. Run it again to update. Install in any order, except:

- `vim` before `vim-coc`;
- the shell modules (`zsh`, `oh-my-zsh`) first, if you want them, so the
  others find your `~/.zshrc`.

## Requirements

Windows 10 version 2004 or later, or Windows 11, with WSL2 and Ubuntu.
Modules are written and tested on **Ubuntu 26.04 LTS**; where an older
release needs something different, the module's README says so.

## License

- Code and configuration files: [MIT](LICENSE).
- Documentation (the guides and the Markdown files in modules):
  [CC BY 4.0](LICENSE-docs). You may copy and adapt it with attribution.
