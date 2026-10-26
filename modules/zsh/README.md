# zsh

Installs [zsh](https://www.zsh.org/) and gives it sensible defaults that
work on their own or alongside a framework such as oh-my-zsh (see the
[`oh-my-zsh`](../oh-my-zsh/) module). Where a framework or another module
already set something up, this one leaves it alone.

| Area | What you get |
|------|--------------|
| PATH | `~/.local/bin` and `~/bin`. zsh doesn't read `~/.profile`, where Ubuntu adds them, so without this, commands installed there aren't found |
| History | 50,000 entries with timestamps, shared between open terminals, no duplicates; a command typed with a leading space isn't saved |
| Up / Down | previous or next command that starts with what you've typed |
| Autosuggestions | a grey suggestion from your history as you type; **Right arrow** accepts it ([zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)) |
| Completion | case-insensitive, colored, pick with the arrow keys |
| Directories | type a directory's name to `cd` into it; `cd -<Tab>` lists recent ones |
| Keys | Ctrl-Left/Right move by word, Ctrl-Delete deletes one, Home/End/Delete work |
| Prompt | `~/code/project main %`, with the git branch, and the `%` red after a failed command. Only if nothing else set a prompt |

## Install

```bash
./install.sh --dry-run    # see what it would do
./install.sh
```

It installs `zsh` and `zsh-autosuggestions` with apt (asking before it uses
`sudo`), adds a marked line to `~/.zshrc` (creating it if needed, which also
skips zsh's first-run wizard), and offers to make zsh your default shell.
Open a new terminal afterwards.

**Check:**

```bash
echo $SHELL                   # /usr/bin/zsh
echo $HISTFILE $SAVEHIST      # ~/.zsh_history 50000
```

Type the start of a command you ran before: a grey suggestion appears, and
Up steps through earlier matches.

### By hand

```bash
sudo apt install zsh zsh-autosuggestions
chsh -s "$(command -v zsh)"
```

Then add the contents of `files/zsh.zsh` to your `~/.zshrc`.

## Remove

```bash
./install.sh --uninstall
chsh -s /bin/bash                                  # optional: back to bash
sudo apt remove zsh-autosuggestions                # optional
```

## Notes

- **With oh-my-zsh**, its `history-substring-search` plugin owns Up/Down,
  and its prompt theme wins; this module's history, completion and
  autosuggestion settings still apply.
- **Changing the default shell** asks for your Linux password. It takes
  effect in new terminals.
