# windows-integration

Open things in Windows, and use the Windows clipboard, from your Linux shell.

| Command | Does | Like macOS's |
|---------|------|--------------|
| `winopen https://example.com` | opens the link in your default Windows browser | `open` |
| `winopen report.pdf` | opens the file with the app Windows uses for it | `open` |
| `winopen .` | opens the folder in Explorer | `open .` |
| `echo hi \| pbcopy` | copies standard input to the Windows clipboard | `pbcopy` |
| `pbpaste` | prints the Windows clipboard's text | `pbpaste` |

It also sets two things in bash and zsh:

- **`BROWSER=winopen`**, so Linux tools that open web pages (`gh`, Python's
  `webbrowser`, ...) open them in Windows instead of failing or starting a
  Linux browser.
- **`alias open=winopen`**, for macOS muscle memory.

## Why

WSL can already run Windows programs, but each has a catch: `explorer.exe`
doesn't understand Linux paths like `/home/you/report.pdf` and reports
failure even when it works; `clip.exe` garbles non-ASCII text from Linux;
and PowerShell's `Get-Clipboard` adds Windows line endings. These scripts
handle all of that, and they find the Windows programs by their full path,
so they work even if Windows' `PATH` isn't added to Linux's
(`appendWindowsPath = false` in `/etc/wsl.conf`).

## Install

```bash
./install.sh --dry-run    # see what it would do
./install.sh
```

Then open a new terminal. It installs:

| What | Where |
|------|-------|
| `winopen`, `pbcopy`, `pbpaste` | `~/.local/bin/` |
| `BROWSER` and the `open` alias | `~/.config/wsl2-dev/windows-integration/shell.sh` |
| a marked line that loads `shell.sh` | `~/.bashrc` and `~/.zshrc` (whichever exist) |

Ubuntu puts `~/.local/bin` on `PATH` at login once the folder exists. If
`winopen` isn't found in a new terminal, add it to `PATH` in your shell's
startup file.

**Check:**

```bash
echo $BROWSER                 # winopen
winopen .                     # Explorer opens this folder
echo "héllo ✓" | pbcopy       # paste in a Windows app: héllo ✓
pbpaste                       # prints what you last copied in Windows
```

### By hand

Copy the three scripts from `files/bin/` to a folder on your `PATH` and make
them executable, then add the contents of `files/shell.sh` to your
`~/.bashrc` or `~/.zshrc`.

## Remove

```bash
./install.sh --uninstall
```

This removes the scripts, the config folder and the marked lines. Your shell
startup files were backed up as `~/.bashrc.wsl2-dev.bak` and
`~/.zshrc.wsl2-dev.bak` the first time the installer changed them.

## Notes

- **`pbpaste` takes a moment**: it has to start PowerShell. It reads text
  only; images and files on the clipboard print nothing.
- **Linux files opened in Windows apps** go through
  `\\wsl.localhost\<distro>\...`. That works, but Windows apps are slow on
  Linux files, so for heavy editing use a Linux-side editor or VS Code's WSL
  extension.
- **Don't set `DISPLAY` yourself.** Old WSL guides derive it from
  `/etc/resolv.conf`; on current WSL, WSLg sets `DISPLAY=:0`, and a wrong
  value makes some tools (e.g. `gh auth login`) hang silently.
- **Ubuntu 22.04 and older** have an `open` command (`xdg-open`); the alias
  takes its place in interactive shells. To keep `xdg-open`, add
  `unalias open` after the marked block (editing `shell.sh` itself is undone
  by the next install).
