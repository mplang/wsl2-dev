# theme

One command to switch the color theme everywhere: Windows Terminal, file
listings, bat, fzf, zsh's suggestions, the tmux status bar, vim, and, if
you ask, Windows' dark mode and accent color.

```bash
theme                         # list themes; * marks the current one
theme tomorrow-night          # switch
theme --windows gruvbox       # switch, and set Windows' mode and accent color too
theme --dry-run modus-vivendi # show what Windows Terminal/Windows would get
```

| Theme | ID | vim | bat |
|-------|----|-----|-----|
| [Gruvbox Dark](https://github.com/morhetz/gruvbox) | `gruvbox` (default) | `gruvbox` | `gruvbox-dark` |
| [Tomorrow Night](https://github.com/chriskempson/tomorrow-theme) | `tomorrow-night` | `Tomorrow-Night` | `base16` |
| [Modus Vivendi](https://protesilaos.com/emacs/modus-themes) | `modus-vivendi` | `modus` | `base16` |

bat has no Tomorrow or Modus theme; `base16` draws with the terminal's 16
colors, so it matches whatever scheme the terminal uses. The terminal
palettes match the [iTerm2-Color-Schemes](https://github.com/mbadolato/iTerm2-Color-Schemes)
versions.

## What a Switch Changes

| What | How | When you see it |
|------|-----|-----------------|
| Windows Terminal | adds the theme's color scheme to its `settings.json` and selects it for **this distro's profile** | immediately |
| `ls`, `lsd`, `eza`, zsh completion | `LS_COLORS`, from the theme's palette | next prompt, in every open shell |
| bat | `BAT_THEME` | next prompt |
| zsh autosuggestions | their color | next prompt |
| fzf | its colors (`FZF_DEFAULT_OPTS_FILE`, fzf 0.47+) | next fzf |
| tmux (with the [`tmux`](../tmux/) module) | the status bar colors | immediately |
| vim (with the [`vim`](../vim/) module) | colorscheme, background, airline theme | when vim regains focus |
| Windows (only with `--windows`) | dark or light mode, and the accent color (taskbar, title bars, Start) | immediately; the taskbar after you sign out |

The choice is per WSL distro (`~/.local/state/wsl2-dev/theme/current`), and
each distro colors only its own Windows Terminal profile. Windows' mode and
accent are shared by every distro, so the last `--windows` switch wins.

Not themed: tools that use the terminal's 16 colors (git, man pages, the
tmux mode indicator, ...) follow the Windows Terminal scheme anyway, so they
change too.

## Install

```bash
./install.sh --dry-run    # see what it would do
./install.sh
```

It installs `theme` to `~/.local/bin`, the themes and helpers to
`~/.config/wsl2-dev/theme/`, and a marked block in `~/.bashrc` and
`~/.zshrc` (whichever exist). With the vim module, it also installs the
Tomorrow and Modus colorschemes. It sets up the shell, tmux and vim colors
for the default theme, and **changes nothing in Windows**: that happens the
first time you run `theme NAME`.

Open a new terminal, then:

```bash
theme --dry-run gruvbox       # check what it would do to Windows Terminal
theme gruvbox
```

### Backups

- **Windows Terminal**: the first change saves its settings as
  `settings.json.before-theme`, next to `settings.json`.
- **Windows** (`--windows`): the first change exports the original registry
  keys to `~/.local/state/wsl2-dev/theme/windows-backup/`. Double-click a
  `.reg` file there (in Explorer: `\\wsl.localhost\<distro>\home\<you>\...`)
  to restore it.

**Several WSL distros?** Each keeps its own Windows backup. If one distro
already changed Windows' colors, a second distro's first `--windows` switch
would back up the *changed* colors. Copy the first distro's backup over
before that, e.g. from the new distro:

```bash
wsl.exe -d <first-distro> --cd '~' -- tar -c .local/state/wsl2-dev/theme/windows-backup | tar -C ~ -x
```

## Your Own Themes

Copy a theme into `~/.config/wsl2-dev/theme/my-themes/` (create it) under a
new name, change the colors, and switch to it. A file there with the same
name as a built-in theme replaces it. `theme --apply` re-applies the current
theme after you edit it. The installer never touches `my-themes/`.

A theme file is bash (`KEY='value'`, and one array). vim reads only the
`VIM_*` and `AIRLINE_THEME` lines, so keep those single-quoted, one per line.

| Key | Used for |
|-----|----------|
| `THEME_NAME` | display name |
| `VIM_COLORSCHEME`, `VIM_BACKGROUND`, `AIRLINE_THEME` | vim (the colorscheme must be installed, e.g. in `~/.config/wsl2-dev/vim/plugins.local.vim`) |
| `BAT_THEME` | bat (`bat --list-themes`) |
| `TERM_SCHEME` | the color scheme's name in Windows Terminal |
| `TERM_BG`, `TERM_FG`, `TERM_CURSOR`, `TERM_SELECTION`, `TERM_ANSI` (16 colors) | the Windows Terminal palette |
| `C_RED` … `C_GRAY` | named colors for file listings (`ls_colors`) |
| `UI_BG1`–`UI_BG3`, `UI_FG`, `UI_FG_DIM`, `UI_FG_ALT`, `UI_ACCENT` | tmux status bar, fzf |
| `UI_HILITE`, `UI_INFO`, `UI_COMMENT` | fzf prompt/matches, fzf counters, autosuggestions |
| `OS_APPEARANCE`, `OS_ACCENT` | Windows' mode (`dark`/`light`) and accent color |

Which file types get which color is in `~/.config/wsl2-dev/theme/ls_colors`
(updated by the installer).

## Remove

```bash
./install.sh --uninstall
```

This removes the command, the themes and the shell hook. Windows Terminal
keeps the scheme it has (pick another in its settings, or restore
`settings.json.before-theme`); the Windows backup and your `my-themes/`
stay.

## Notes

- **Windows Terminal's settings** must be plain JSON for the theme to update
  them. If yours has comments, `theme` says so; set the color scheme in
  Windows Terminal's settings instead (the scheme's colors are in the theme
  file).
- **Profile names**: `theme` finds this distro's profile by its name (e.g.
  *Ubuntu-26.04*). If you renamed it, it colors every WSL profile instead.
- **Needs python3** (Ubuntu has it) to edit Windows Terminal's settings and
  the registry.
