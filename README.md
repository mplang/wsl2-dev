# wsl2-dev

Guides and small, independent tooling modules for developing on
[WSL2](https://learn.microsoft.com/windows/wsl/about) with Ubuntu.

Take what you want and skip the rest: no module requires another. If you
don't use vim, nothing here touches vim.

## Guides

| Guide | For |
|-------|-----|
| [Developing on WSL2 (Ubuntu)](guides/developer-guide.md) | Installing WSL2, the filesystem, Windows interop, VS Code, git and SSH, Node and Java, troubleshooting, and notes for people coming from macOS |

## Modules

Each module is a folder under [`modules/`](modules/) with a README (what it
does, why, how to install and remove it by hand) and an `install.sh` that
does the same for you. See [modules/README.md](modules/README.md) for how
they're put together.

| Module | What it does |
|--------|--------------|
| [`windows-integration`](modules/windows-integration/) | Open URLs, files and folders in Windows (`winopen`, `open`, `BROWSER`), and `pbcopy`/`pbpaste` for the Windows clipboard |
| [`ssh-agent`](modules/ssh-agent/) | One SSH agent for every shell (keychain): type your key's passphrase once per WSL session |

Planned, one at a time:

| Module | What it does |
|--------|--------------|
| `cli-tools` | bat, lsd, eza, ripgrep and glow, with aliases |
| `zsh` | oh-my-zsh with a curated plugin set, autosuggestions and larger, de-duplicated history |
| `fzf` | fzf with ripgrep for file search, bat previews and fzf-tab completion |
| `tmux` | A tmux config: `Ctrl-Space` prefix, mouse, clipboard to Windows (OSC 52), plugins via TPM, status bar |
| `vim` | A vim config and plugin set (vim-plug) |
| `vim-coc` | Language-server completion in vim with CoC (needs `vim` and node) |
| `git` | WSL-friendly git settings: line endings, `zdiff3` conflicts, VS Code as diff and merge tool |
| `python-uv` | Python projects with uv; direnv activates each project's `.venv` |
| `node-nvm` | Node versions per project with nvm; direnv switches them |
| `theme` | One command to switch the color theme of Windows Terminal, Windows' accent, the shell, tmux, vim and fzf (Gruvbox, Tomorrow Night, Modus Vivendi) |

## Requirements

Windows 10 version 2004 or later, or Windows 11, with WSL2 and Ubuntu.
Modules are written and tested on **Ubuntu 26.04 LTS**; where an older
release needs something different, the module's README says so.

## License

- Code and configuration files: [MIT](LICENSE).
- Documentation (the guides and the Markdown files in modules):
  [CC BY 4.0](LICENSE-docs). You may copy and adapt it with attribution.
