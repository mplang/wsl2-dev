# cli-tools

Modern replacements for everyday commands, with short aliases.

| Tool | Replaces | What you get |
|------|----------|--------------|
| [bat](https://github.com/sharkdp/bat) | `cat`, `less` | syntax highlighting, line numbers, git changes in the margin, paging |
| [lsd](https://github.com/lsd-rs/lsd) | `ls` | colors, readable sizes and dates, tree view, optional icons |
| [eza](https://github.com/eza-community/eza) | `ls` | another modern `ls`; used by the `fzf` module's previews |
| [ripgrep](https://github.com/BurntSushi/ripgrep) (`rg`) | `grep -r` | fast recursive search that skips `.gitignore`d files |
| [glow](https://github.com/charmbracelet/glow) | — | Markdown rendered in the terminal |

Aliases and helpers (bash and zsh; each only if its tool is installed):

| Command | Does |
|---------|------|
| `ls` | `lsd` |
| `ll` | long listing |
| `la` | long listing, including dotfiles |
| `lt` | tree, two levels deep |
| `man <cmd>` | man pages colored by bat |
| `battail <file>` | `tail -f` with highlighting, for logs |
| `bathelp <cmd> [args]` | a command's `--help`, colored |

`cat` and `grep` are left alone: `bat` and `rg` are there when you want them,
and scripts or habits that expect the originals keep working.

## Install

```bash
./install.sh --dry-run    # see what it would do
./install.sh
```

It installs the packages with apt (asking before it uses `sudo`), adds a
`bat` command (Ubuntu installs bat as `batcat`), and adds a marked line to
`~/.bashrc` and `~/.zshrc` (whichever exist) that loads
`~/.config/wsl2-dev/cli-tools/shell.sh`. Open a new terminal afterwards.

**Check:**

```bash
ll
lt
bat README.md
rg -n TODO
glow README.md
```

### File icons

lsd can show an icon per file type. Icons need a
[Nerd Font](https://www.nerdfonts.com/) in your terminal, otherwise they show
as boxes, so they're off by default. To turn them on:

1. Download a Nerd Font, e.g. `Hack.zip` from the
   [Nerd Fonts releases](https://github.com/ryanoasis/nerd-fonts/releases/latest),
   select its `*NerdFontMono-*.ttf` files and choose *Install for all users*.
2. In Windows Terminal, go to Settings → **Defaults** → Appearance and set
   the font face (e.g. *Hack Nerd Font Mono*).
3. Add `export WSL2DEV_ICONS=1` to `~/.bashrc` or `~/.zshrc`, **above** the
   `wsl2-dev:cli-tools` block, and open a new terminal.

### Older Ubuntu releases

Ubuntu 26.04 has all five tools in apt. 24.04 lacks glow, and 22.04 lacks
lsd, eza and glow; the installer says which it skipped. Install those from
their projects' release pages, and glow from Charm's apt repository:

```bash
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" \
    | sudo tee /etc/apt/sources.list.d/charm.list
sudo apt update && sudo apt install glow
```

Then run the installer again.

### By hand

```bash
sudo apt install bat lsd eza ripgrep glow
mkdir -p ~/.local/bin && ln -s /usr/bin/batcat ~/.local/bin/bat
```

Then add the contents of `files/shell.sh` to your `~/.bashrc` or `~/.zshrc`.

## Remove

```bash
./install.sh --uninstall
sudo apt remove bat lsd eza ripgrep glow      # optional
```

This removes the aliases, the config folder and the `bat` link; the packages
stay unless you remove them.
