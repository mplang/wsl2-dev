# ssh-agent

One SSH agent for your whole WSL session: type each key's passphrase once,
and every terminal, tmux pane and git command after that uses the unlocked
key.

## Why

WSL has no desktop keyring to hold your SSH keys, so out of the box you
either type the passphrase on every `git push`, or run
`eval "$(ssh-agent)"` in each terminal and end up with a separate agent per
terminal. [keychain](https://github.com/funtoo/keychain) starts one agent
with the first shell and points every later shell at it.

## Install

```bash
./install.sh --dry-run    # see what it would do
./install.sh
```

It installs the `keychain` package (asking before it uses `sudo`), and adds
a marked line to `~/.bashrc` and `~/.zshrc` (whichever exist) that loads
`~/.config/wsl2-dev/ssh-agent/shell.sh`.

Open a new terminal. The first one asks for your key's passphrase; later
ones don't, until WSL shuts down (`wsl --shutdown`, or a Windows restart).

**Which keys:** every `~/.ssh/id_*` that has a matching `.pub` file (e.g.
`id_ed25519`). No key yet? Create one with `ssh-keygen -t ed25519`, then open
a new terminal.

**Check:**

```bash
ssh-add -l                # lists your key(s)
ssh -T git@github.com     # no passphrase prompt
```

### By hand

```bash
sudo apt install keychain
```

Then add the contents of `files/shell.sh` to your `~/.bashrc` or `~/.zshrc`.

## Remove

```bash
./install.sh --uninstall
sudo apt remove keychain      # optional
```

## Notes

- **Programs that don't start a shell** (VS Code's WSL server, cron, editor
  plugins) can join the agent by sourcing the file keychain writes:
  `. ~/.keychain/$(hostname)-sh`.
- **oh-my-zsh users**: the `keychain` plugin does the same job. Use one or
  the other.
- **Keys kept in Windows** (the Windows OpenSSH agent, 1Password, ...) need a
  bridge into WSL instead (e.g. `npiperelay` with `socat`); that's outside
  this module.
