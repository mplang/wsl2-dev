# oh-my-zsh

[oh-my-zsh](https://ohmyz.sh/), the popular zsh framework, with a small set
of plugins that earn their place, and optionally the
[powerlevel10k](https://github.com/romkatv/powerlevel10k) prompt.

| Plugin | What it does |
|--------|--------------|
| [git](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git) | short aliases: `gst` = `git status`, `gco` = `git checkout`, `gl` = `git pull`, ... |
| [history-substring-search](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/history-substring-search) | Up/Down step through history entries that contain what you've typed |
| [colored-man-pages](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/colored-man-pages) | readable man pages |
| [command-not-found](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/command-not-found) | suggests the apt package for a command you don't have |
| [dirhistory](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/dirhistory) | Alt-Left/Right: back and forward through directories, Alt-Up: parent |

Needs zsh (the [`zsh`](../zsh/) module installs it, along with history and
completion defaults that work well with oh-my-zsh) and git.

## Install

```bash
./install.sh --dry-run    # see what it would do
./install.sh              # or: ./install.sh --p10k
```

It clones oh-my-zsh to `~/.oh-my-zsh` (it updates itself from there) and
adds a marked line at the **top** of `~/.zshrc` that loads
`~/.config/wsl2-dev/oh-my-zsh/oh-my-zsh.zsh`. Loading the framework first
lets your own settings, and other modules', override its defaults. Open a
new terminal afterwards.

The installer doesn't use oh-my-zsh's own install script, which replaces
`~/.zshrc` with its template.

### Your settings

The installer creates `~/.config/wsl2-dev/oh-my-zsh/local.zsh` once. It's
yours: updates never change it, and uninstalling keeps it. It's loaded just
before oh-my-zsh, so it can change the theme or the plugins:

```zsh
ZSH_THEME=agnoster                 # https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
plugins+=(docker kubectl)          # https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins
plugins+=(vi-mode)                 # vi keys on the command line
plugins=(${plugins:#dirhistory})   # drop one of the defaults
```

### powerlevel10k

`./install.sh --p10k` also clones powerlevel10k and selects it in
`local.zsh`. Its setup wizard runs in the first new terminal; run
`p10k configure` to redo it. It needs a [Nerd Font](https://www.nerdfonts.com/)
for its icons: install one (e.g. *Hack Nerd Font Mono* from `Hack.zip` in the
[Nerd Fonts releases](https://github.com/ryanoasis/nerd-fonts/releases/latest))
and select it in Windows Terminal under Settings → **Defaults** →
Appearance.

The wizard adds two things to `~/.zshrc` itself: an "instant prompt" block
at the very top, and a line at the end that loads `~/.p10k.zsh`. Both are
fine to keep.

## Remove

```bash
./install.sh --uninstall
rm -rf ~/.oh-my-zsh            # optional: oh-my-zsh itself
```

The uninstaller removes the marked line and the module's file, and keeps
your `local.zsh`.

## Notes

- **Multi-line paste in tmux**: oh-my-zsh's paste handling garbles
  multi-line pastes in tmux when zsh-autosuggestions is loaded, so this
  module restores zsh's plain bracketed paste.
- **Updates**: oh-my-zsh checks for updates every couple of weeks and asks
  before installing them; `omz update` updates now.
