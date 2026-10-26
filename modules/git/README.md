# git

Git settings that suit WSL, plus a handful of modern defaults. They go in a
file of their own that `~/.gitconfig` includes **at the top**, so anything
you already set in `~/.gitconfig` still wins.

| Setting | Why |
|---------|-----|
| `core.autocrlf = input` | Commit LF line endings and never convert on checkout. Code that runs in Linux needs LF; a stray CRLF breaks shell scripts |
| `init.defaultBranch = main` | New repositories start on `main` |
| `diff.algorithm = histogram` | Clearer diffs when code moves around |
| `merge.conflictstyle = zdiff3` | Conflicts also show what the code looked like before both changes (`diff3` on git older than 2.35) |
| `rerere.enabled = true` | Git remembers how you resolved a conflict and reuses it |
| `pull.rebase = true` | `git pull` replays your local commits on top instead of adding a merge commit |
| `rebase.updateRefs = true` | Rebasing a stack of branches moves all of them |
| `fetch.prune = true` | Branches deleted on the remote disappear locally too |
| `push.default = current`, `push.autoSetupRemote = true` | `git push` on a new branch just works, no `--set-upstream` |
| `branch.sort = -committerdate` | `git branch` lists recent branches first |

And, when the installer finds them:

| If found | Setting |
|----------|---------|
| VS Code's `code` command (Windows VS Code with WSL support) | VS Code as the tool for `git difftool` and `git mergetool` |
| [Git Credential Manager](https://github.com/git-ecosystem/git-credential-manager) on Windows (it comes with [Git for Windows](https://gitforwindows.org/)) | HTTPS remotes sign in through Windows: browser sign-in, two-factor, and tokens kept in the Windows credential store |

## Install

```bash
./install.sh --dry-run    # see what it would do
./install.sh
```

It writes `~/.config/wsl2-dev/git/config` for this machine and adds a marked
`[include]` at the top of `~/.gitconfig` (creating it if needed). Install VS
Code or Git for Windows later? Run the installer again to pick them up.

If you haven't yet, set who you are:

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

**Check:**

```bash
git config --show-origin --get core.autocrlf     # ...wsl2-dev/git/config  input
git config --get merge.conflictstyle             # zdiff3
```

### Disagree with a setting?

Set it in `~/.gitconfig`; yours wins. For example, to keep merge commits on
pull:

```bash
git config --global pull.rebase false
```

### By hand

Run the `git config --global ...` commands for the settings you want; the
table above lists them. For Git Credential Manager, check which of
`ucrt64` (Git for Windows 2.56 and later), `mingw64` (older) or `clangarm64`
(ARM) exists under `C:\Program Files\Git`, then:

```bash
git config --global credential.helper "/mnt/c/Program\ Files/Git/ucrt64/bin/git-credential-manager.exe"
git config --global credential.https://dev.azure.com.useHttpPath true    # for Azure DevOps
```

## Remove

```bash
./install.sh --uninstall
```

This removes the `[include]` and the module's file. Settings you made with
`git config --global` stay.

## Notes

- **SSH or HTTPS?** For GitHub and similar, an SSH key (see the
  [`ssh-agent`](../ssh-agent/) module) needs no Windows parts at all. Git
  Credential Manager is the easier route for HTTPS remotes, especially Azure
  DevOps and other sign-in-heavy hosts.
- **Git Credential Manager** setup follows
  [GCM's WSL guide](https://github.com/git-ecosystem/git-credential-manager/blob/main/docs/wsl.md)
  for Git for Windows. A standalone GCM install (without Git for Windows)
  also needs `WSLENV` set in Windows, so the installer doesn't use it; see
  that guide. GCM runs as a Windows program and reads Git for Windows'
  settings (e.g. proxy settings go in `%UserProfile%\.gitconfig`).
