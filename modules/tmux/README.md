# tmux

A [tmux](https://github.com/tmux/tmux) setup for Windows Terminal: tabs and
split panes inside one terminal that survive closing it, with mouse support,
copies that land on the Windows clipboard, and a clear status bar.

| Key | Does |
|-----|------|
| **Ctrl-Space** | the prefix: press it, let go, then the key below |
| prefix **-** / **\|** | split the pane below / beside, in the same directory |
| prefix **H J K L** | resize the pane (hold to repeat) |
| **Alt-Shift-H / L** | previous / next window (no prefix) |
| prefix **c**, **n**, **p**, **&** | new, next, previous, close window |
| prefix **[** | copy mode: scroll and select with vi keys, **v** to start, **y** to copy |
| mouse | click panes and windows, drag borders, scroll back, drag to select and copy |
| prefix **Tab** | pick text on screen (paths, URLs, words) with fzf and paste it (extrakto) |
| prefix **R** | reload your config |
| prefix **d** | detach; `tmux attach` comes back to everything as you left it |

Windows and panes are numbered from 1. Copies (mouse or `y`) go straight to
the Windows clipboard: tmux sends them to Windows Terminal (OSC 52), so no
helper program is needed.

**Status bar:** session name, windows (the current one highlighted, `*Z`
when a pane is zoomed), time, date, host name, and the mode (PREFIX, COPY,
...).

Plugins, installed by [TPM](https://github.com/tmux-plugins/tpm) on first
start:

| Plugin | What it does |
|--------|--------------|
| [tmux-sensible](https://github.com/tmux-plugins/tmux-sensible) | widely agreed-on defaults |
| [tmux-mode-indicator](https://github.com/MunifTanjim/tmux-mode-indicator) | shows PREFIX / COPY / SYNC in the status bar |
| [extrakto](https://github.com/laktak/extrakto) | prefix Tab: pick text from the screen with fzf (needs fzf: the [`fzf`](../fzf/) module, and python3) |

## Install

```bash
./install.sh --dry-run    # see what it would do
./install.sh
```

It installs `tmux` (and `git`, for TPM) with apt, asking before it uses
`sudo`. It adds two marked lines to `~/.tmux.conf`, creating it if needed (or
uses `~/.config/tmux/tmux.conf` if that's where your config is):

- **at the top**, loading `~/.config/wsl2-dev/tmux/tmux.conf`, so your own
  settings below it win;
- **at the end**, loading `plugins.conf`, which starts TPM. TPM has to come
  last so it sees every plugin, including your own.

Start `tmux`. The first start clones TPM and installs the plugins. If tmux
is already running with this config, the installer reloads it.

**Check:** `tmux`, then press Ctrl-Space then `|`: the window splits.

### Your own settings

Put them in `~/.tmux.conf` between the two marked blocks:

```tmux
set -g @wsl2dev-powerline on            # arrow-shaped separators (need a Nerd Font)
set -g status-position top              # status bar at the top
set -g @plugin 'jaclu/tmux-power-zoom'  # more plugins: then prefix I to install
```

**Powerline arrows** need a [Nerd Font](https://www.nerdfonts.com/) in
Windows Terminal (e.g. *Hack Nerd Font Mono*, from `Hack.zip` in the
[Nerd Fonts releases](https://github.com/ryanoasis/nerd-fonts/releases/latest),
selected under Settings → **Defaults** → Appearance).

**Colors** are Gruvbox Dark, set as `@thm_*` options at the top of
`~/.config/wsl2-dev/tmux/tmux.conf`; set any of them in `~/.tmux.conf` to
change it.

**Plugins:** prefix **I** installs plugins you've added, prefix **U** updates
them.

### By hand

```bash
sudo apt install tmux git
```

Add `source-file /path/to/files/tmux.conf` at the top of `~/.tmux.conf` and
`source-file /path/to/files/plugins.conf` at the end.

## Remove

```bash
./install.sh --uninstall
tmux kill-server                 # restart tmux without the settings
rm -rf ~/.tmux/plugins           # optional: the plugins
```

## Notes

- **vim users**: the [`vim`](../vim/) module adds seamless Ctrl-H/J/K/L
  movement between vim splits and tmux panes. It isn't here because it takes
  over Ctrl-L (clear screen) in every pane.
- **Start tmux with every terminal**: oh-my-zsh's `tmux` plugin does this.
  With the [`oh-my-zsh`](../oh-my-zsh/) module, add
  `plugins+=(tmux)` and `ZSH_TMUX_AUTOSTART=true` to its `local.zsh`.
- **Shift-Enter**: tmux passes it through as a distinct key (extended keys),
  for apps that use it.
