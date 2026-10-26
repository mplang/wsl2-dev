# python-uv

Python projects with [uv](https://docs.astral.sh/uv/), activated
automatically by [direnv](https://direnv.net/): `cd` into a project and its
virtual environment is on, with exactly the packages its lock file lists;
`cd` out and it's off.

- **uv** replaces pip, venv, pip-tools and pyenv in one fast tool: it
  creates the project, manages dependencies (`pyproject.toml` +
  `uv.lock`), and installs Python versions.
- **direnv** runs a project's `.envrc` when you enter the directory. This
  module adds `layout uv` for it: sync `.venv` from `uv.lock`, then activate
  it.

## Install

```bash
./install.sh --dry-run    # see what it would do
./install.sh
```

It installs uv with [Astral's installer](https://docs.astral.sh/uv/getting-started/installation/)
into `~/.local/bin` (without letting it edit your shell files), direnv with
apt (asking before it uses `sudo`), `layout uv` as
`~/.config/direnv/lib/wsl2-dev-uv.sh`, and a marked block in `~/.bashrc` and
`~/.zshrc` (whichever exist) that hooks direnv into the shell and adds tab
completion for `uv`. Open a new terminal afterwards.

## Use

**A new project:**

```bash
uv init myproject && cd myproject
echo 'layout uv' > .envrc
direnv allow                  # trust this .envrc (again after you edit it)
uv add requests               # add a dependency; .venv updates
python                        # .venv's Python, with requests
```

**An existing uv project** (has `pyproject.toml` and `uv.lock`): add the
same `.envrc` and `direnv allow`. Entering the directory creates `.venv`
and installs the locked packages. Commit `.envrc` so others get the same.

**Other things uv does:**

```bash
uv python pin 3.13            # use Python 3.13 here (uv downloads it if needed)
uv run pytest                 # run a command in the project's environment
uvx ruff check .              # run a tool without installing it
uv tool install ruff          # install a tool for good (~/.local/bin)
uv self update                # update uv
```

**Check:** in a project with the `.envrc` above, `echo $VIRTUAL_ENV` shows
its `.venv`, and it's empty again after `cd ..`.

### By hand

```bash
curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh
sudo apt install direnv
mkdir -p ~/.config/direnv/lib && cp files/direnv-uv.sh ~/.config/direnv/lib/wsl2-dev-uv.sh
```

Then add `eval "$(direnv hook bash)"` (or `zsh`) at the end of your
`~/.bashrc` or `~/.zshrc`.

## Remove

```bash
./install.sh --uninstall
```

This removes the hook block and `layout uv`. To remove uv itself:

```bash
uv cache clean
rm -rf "$(uv python dir)" "$(uv tool dir)"
rm ~/.local/bin/uv ~/.local/bin/uvx
```

## Notes

- **direnv's output**: direnv lists the variables it changes each time you
  enter or leave. To hide that list, add `hide_env_diff = true` under
  `[global]` in `~/.config/direnv/direnv.toml`.
- **`layout uv`** is built into direnv 2.38 and later; this module's copy
  (from direnv's own code) only applies when the installed direnv lacks it.
  Ubuntu 26.04 has direnv 2.37.
- **oh-my-zsh users** with its `direnv` plugin: this module sees the plugin's
  hook and doesn't add a second one.
- **The [`node-nvm`](../node-nvm/) module** also uses direnv; installing both
  is fine.
