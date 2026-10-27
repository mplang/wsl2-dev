# AGENTS.md

Instructions for AI coding agents (and humans) working in this repository.
Read [README.md](README.md) and [modules/README.md](modules/README.md)
first; this file covers what they don't: how to change things safely, and
how to keep the several descriptions of the same thing in agreement.

## What This Repository Is

- **Public.** Everything committed here is published. Never add personal
  paths, hostnames, usernames, email addresses (other than the author's in
  `LICENSE`), keys, or machine-specific settings. Examples use placeholders
  like `<you>`, `you@example.com` and `~/repos/my-project`.
- **Two kinds of content**, under two licenses (see the README):
  - **Guides** (`guides/`): prose for people setting up WSL2 by hand.
  - **Modules** (`modules/<name>/`): one optional, independent tool setup
    each, with a README and an `install.sh`.
- **Independent modules.** No module requires another, except `vim-coc`
  needing `vim`. A module may *extend* another only through the drop-in
  files listed in modules/README.md (`*/vim-plugins.vim`,
  `*/vim-config.vim`, `*/tmux-plugins.conf`), which do nothing when the
  other module is absent. Don't add new cross-module dependencies.
- **Target:** Ubuntu 26.04 LTS on WSL2. Where an older release (24.04,
  22.04) needs something different, the module handles it and its README
  says so.

## Layout

```
README.md                       overview, guide and module tables, quick start
AGENTS.md                       this file
guides/developer-guide.md       the full guide, with "Module:" notes
guides/developer-guide-standalone.md
                                the same guide with no references to this repo
lib/common.sh                   shared helpers, sourced by every install.sh
modules/README.md               how modules hook in; the install.sh contract
modules/<name>/README.md        what the module does, manual install/removal
modules/<name>/install.sh       installs, updates (--dry-run, --uninstall)
modules/<name>/files/           what gets installed
tools/check-guides              diffs the two guides (see below)
```

## Keeping the Documentation in Sync

The same facts appear in several places. When you change one, update the
others **in the same commit**.

### The two guides

`guides/developer-guide.md` is the **source**.
`guides/developer-guide-standalone.md` is the same text minus everything
that refers to this repository, so it can be shared or copied on its own.

Rules:

1. Make content changes in `developer-guide.md` first, then apply the same
   change to the standalone guide. This includes fixes, new sections,
   version numbers and links.
2. Repository-specific text exists **only** in the full guide, and only in
   these forms, so it can be stripped mechanically:
   - blockquotes that start with `> **Module:**` or `> **Modules:**`, each a
     single line;
   - the `> **Ready-made setups.**` note in the introduction;
   - the Further Reading line that starts with `- This repository's modules`.

   Don't refer to modules or `../modules/` anywhere else in the guide (not
   in body text, tables or section links).
3. The standalone guide has a few passages of its own. Where a module note
   carried advice a reader needs, the standalone guide gives that advice
   directly, without the tooling. Currently:
   - §9 (GitHub over SSH): the `keychain` tip, for one ssh-agent across
     terminals;
   - §12 (Clipboard and "open"): `pbcopy`/`pbpaste` **functions** in place
     of the plain aliases, and the note about `explorer.exe` and Linux
     paths.

   If you add a module note that hides something a reader needs, add an
   equivalent standalone passage, and list it here.
4. Check the result:

   ```bash
   tools/check-guides
   ```

   It strips the repository-specific parts from the full guide and diffs
   the result against the standalone guide. The diff must show **only** the
   standalone-only passages listed in rule 3. Anything else is drift: fix
   whichever guide is wrong.
5. The standalone guide must not mention this repository:

   ```bash
   grep -nEi 'module|wsl2-dev|\.\./' guides/developer-guide-standalone.md
   ```

   should print nothing.

### Module notes in the full guide

Each `> **Module:**` note is a one- or two-sentence summary of a module.
When a module's behavior changes, check its note (search the guide for
`modules/<name>/`). Keep notes short: what the module adds beyond the
guide's manual steps, then the link. The module's README is the full
description.

### A module's descriptions

A module is described in up to five places. Its `install.sh` and `files/`
are the truth; the rest must match them:

| Where | What it says |
|-------|--------------|
| `modules/<name>/install.sh` header comment | what it installs and where |
| `modules/<name>/README.md` | full description; manual install and removal steps that do exactly what `install.sh` does |
| `README.md` module table | one line |
| `guides/developer-guide.md` | the `> **Module:**` note, if there is one |
| `modules/README.md` | the hook table and the extension-point table, if the module hooks in a new way or uses or provides a drop-in file |

When you add a module, add it to the README's module table (in the order
modules are usually installed), give it a README following the existing
ones, and add a guide note where a section covers the same ground.

### Other shared facts

- **Versions** pinned in docs (e.g. the nvm installer URL, currently
  `v0.40.8`, in both guides and the `node-nvm` README): change all
  occurrences together (`grep -rn 'v0\.40' .`).
- **Requirements** (Windows and Ubuntu versions) appear in the README and
  §1 of both guides.
- **Install order and the `vim-coc` exception** appear in the README (intro
  and Quick Start) and modules/README.md.

## Changing Modules

### The install.sh contract

Every `install.sh` sets `MODULE`, sources `lib/common.sh`, and calls
`parse_args "$@"`. It must:

- be **idempotent**: a second run changes nothing;
- support `--dry-run` (change nothing, say what would change) and
  `--uninstall` (remove only what it installed);
- go through the helpers in `lib/common.sh` for every change:
  `install_file`, `add_hook`/`remove_hook`, `remove_file`, `remove_dir`,
  `backup_once`, `apt_install`, `check_free`. They implement dry runs,
  backups, the `# >>> wsl2-dev:<module> >>>` markers, and the refusal to
  overwrite files the module didn't create;
- ask before `sudo` (`apt_install` does), and never write outside `$HOME`
  otherwise;
- never overwrite a user's config file; add a marked hook instead (see
  modules/README.md for which tool gets which hook, and where).

Installed files carry the module's tag (`wsl2-dev:<module>`) so
`install_file` can tell them apart from the user's files. Keep it in new
files.

### Style

- bash for installers and scripts (`#!/usr/bin/env bash`), POSIX-ish `sh`
  only where a file is sourced by both bash and zsh (`files/shell.sh`).
- Match the surrounding code: comment density, naming, the header comment
  format of `install.sh`.
- Docs: plain, direct sentences; tables for reference material; commands
  in fenced blocks with short trailing comments. Keep each file's existing
  heading style.
- Files use LF line endings (`.gitattributes` enforces this).

## Testing

Test on WSL2 Ubuntu, without touching the real user setup:

```bash
export HOME=$(mktemp -d) WSL2DEV_SKIP_APT=1   # fake home; skip apt
cd modules/<name>
bash -n install.sh                            # syntax
./install.sh --dry-run && ./install.sh        # install
./install.sh                                  # again: should change nothing
./install.sh --uninstall                      # should leave $HOME as it was
```

- Run each in a fresh shell (or subshell) so the fake `HOME` doesn't leak.
- Check files sourced by shells with both `bash -n` and `zsh -n`, and time
  zsh startup (`time zsh -i -c exit`) after changing shell hooks.
- **tmux:** use an isolated server (`tmux -S "$HOME/sock" ...` or
  `TMUX_TMPDIR`); never reload or kill the user's running tmux.
- **Windows:** never change the real Windows Terminal settings or the
  registry in a test. Use `theme --dry-run` or `theme --no-terminal`, and
  don't run `theme --windows` without the user's explicit request.
- **apt:** with `WSL2DEV_SKIP_APT=1`, installers skip package installs; the
  packages must already be present for later steps to work.
- Clean up temporary homes when done.

Before committing, also run `tools/check-guides` if either guide changed.

## Commits

- One topic per commit; the message says what changed and why.
- Push only when the maintainer has approved it; this repository is public.
- Don't commit generated files (`__pycache__/`, backups such as
  `*.wsl2-dev.bak`).
