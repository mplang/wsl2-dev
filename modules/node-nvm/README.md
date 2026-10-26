# node-nvm

[Node.js](https://nodejs.org/) through [nvm](https://github.com/nvm-sh/nvm),
so you can install several versions side by side and switch per project,
plus [direnv](https://direnv.net/) to make the switch automatic: `cd` into a
project and its `.nvmrc` version is the active `node`.

- **nvm** installs node versions in your home directory: no `sudo`, and
  global packages (`npm install -g`) just work.
- **direnv** runs a project's `.envrc` when you enter the directory. This
  module adds `use nvm` for it.

## Install

```bash
./install.sh --dry-run    # see what it would do
./install.sh
```

It installs direnv with apt (asking before it uses `sudo`), nvm's latest
release into `~/.nvm` (without letting its installer edit your shell files),
the latest LTS version of node, `use nvm` as
`~/.config/direnv/lib/wsl2-dev-nvm.sh`, and a marked block in `~/.bashrc`
and `~/.zshrc` (whichever exist). Open a new terminal afterwards.

**Check:** `node --version` and `nvm --version`.

## Use

```bash
nvm install 22                # another version
nvm ls                        # installed versions
nvm alias default 22          # the version new terminals use
```

**Per project:**

```bash
cd myproject
node --version > .nvmrc       # or e.g.: echo 22 > .nvmrc
echo 'use nvm' > .envrc
direnv allow                  # trust this .envrc (again after you edit it)
```

Entering the directory now switches to the `.nvmrc` version, installing it
first if needed. Commit `.nvmrc` and `.envrc` so others get the same.

## How it stays fast

Loading nvm the usual way adds seconds to every new terminal, mostly to
work out the default version. This module instead loads nvm the first time
you run `nvm`, and puts the default version on `PATH` itself, reading
`~/.nvm/alias/default`:

| Default alias | node on PATH |
|---------------|--------------|
| an exact version, e.g. `v22.11.0` | that version |
| a major version, e.g. `22` | the newest installed 22.x |
| anything else (`node`, `lts/*`, ...) | the newest installed version |

`nvm use` and everything else nvm does work as usual.

### By hand

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.8/install.sh | PROFILE=/dev/null bash
sudo apt install direnv
mkdir -p ~/.config/direnv/lib && cp files/direnv-nvm.sh ~/.config/direnv/lib/wsl2-dev-nvm.sh
```

(Check [nvm's README](https://github.com/nvm-sh/nvm#installing-and-updating)
for the current version.) Then add to your `~/.bashrc` or `~/.zshrc`:

```bash
export NVM_DIR="$HOME/.nvm"
. "$NVM_DIR/nvm.sh"
eval "$(direnv hook bash)"    # or zsh
```

## Remove

```bash
./install.sh --uninstall
rm -rf ~/.nvm                 # optional: nvm and every node version
```

## Notes

- **oh-my-zsh's `nvm` plugin** loads nvm too; use one or the other.
- **The [`vim-coc`](../vim-coc/) module** finds node in `~/.nvm` even when
  vim starts before nvm is loaded.
- **The [`python-uv`](../python-uv/) module** also uses direnv; installing
  both is fine, and direnv is hooked into the shell once.
- **Updating nvm**: `cd ~/.nvm && git fetch --tags && git checkout <newest tag>`,
  or run nvm's install script again.
