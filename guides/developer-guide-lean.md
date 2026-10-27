# Developing on WSL2 (Ubuntu): The Short Version

[WSL2](https://learn.microsoft.com/windows/wsl/about) runs a real Linux
environment on Windows, with no dual-booting or hand-built virtual machine.
This is the condensed path from nothing to a working setup. For the reasoning
behind each step, see the [full guide](developer-guide.md).

Commands run in the **Ubuntu** shell unless marked **PowerShell**.

## 1. Install

You need Windows 10 version 2004 (build 19041) or later, or Windows 11, with
hardware virtualization enabled (Task Manager → Performance → CPU shows
"Virtualization: Enabled").

In **PowerShell as Administrator**:

```powershell
wsl --install                 # WSL2 + Ubuntu; reboot when prompted
wsl --list --online           # other distributions and versions
wsl --install -d Ubuntu-26.04 # a specific one
```

After the reboot, Ubuntu asks for a Linux username and password. The
password is for `sudo`, and it's separate from your Windows password.

**Check** (PowerShell): `wsl --list --verbose` shows your distro with
version 2.

If `wsl --install` only prints help text, or the Microsoft Store is blocked,
use `wsl --install --inbox`, or Microsoft's
[manual steps](https://learn.microsoft.com/windows/wsl/install-manual).

## 2. Windows Terminal

Use [Windows Terminal](https://learn.microsoft.com/windows/terminal/) (built
into Windows 11). In Settings (`Ctrl+,`):

1. Set **Default profile** to **Ubuntu**.
2. In the Ubuntu profile, clear **Starting directory**, so new tabs open in
   your Linux home instead of `/mnt/c/Users/<you>`.

**Optional: limit WSL's memory and CPUs** with `C:\Users\<you>\.wslconfig`,
then run `wsl --shutdown` to apply it:

```ini
[wsl2]
memory=8GB
processors=4
```

## 3. The One Rule: Keep Your Code in Linux

Linux has its own filesystem; your home is `/home/<you>` (`~`).

- **Keep projects under `~`.** Work on files in `/mnt/c` (your C: drive)
  from Linux is much slower; `git status` and `npm install` crawl.
- From Windows, reach Linux files at `\\wsl$\Ubuntu\home\<you>`, or run
  `explorer.exe .` in a Linux folder.
- Don't let Windows programs *write* to Linux files (e.g. a Windows git
  client on a repo in `~`). Reading is fine.

## 4. Linux Essentials

Software comes from the package manager, `apt`, not installers:

```bash
sudo apt update && sudo apt upgrade -y   # update everything (do this now, and regularly)
sudo apt install <package>
apt search <term>
```

| Command | Does |
|---------|------|
| `pwd`, `cd`, `ls -alh` | where am I, move, list (with hidden files) |
| `cat`, `less` | print a file, page through one (`q` quits) |
| `cp`, `mv`, `rm -r` | copy, move, delete; **no recycle bin** |
| `mkdir -p a/b/c` | make directories, parents included |
| `grep -r "text" .`, `find . -name '*.ts'` | search contents, find files |
| `man <cmd>`, `<cmd> --help` | documentation |
| `chmod +x script.sh`, `./script.sh` | make a script runnable, run it |

**Tab** completes, **Ctrl+R** searches history, **Ctrl+C** stops a command.

### zsh

Switch to zsh before installing language tools, so their setup lands in the
right file:

```bash
sudo apt install -y zsh
chsh -s "$(which zsh)"        # then close and reopen the terminal
```

On first start zsh offers to create `~/.zshrc`; the defaults are fine. That
file is your shell profile: `PATH`, aliases and tool setup go there, and
`source ~/.zshrc` reloads it. [Oh My Zsh](https://ohmyz.sh/) is a popular,
optional add-on for themes and plugins.

## 5. Windows and Linux Together

```bash
explorer.exe .          # this folder in Explorer
code .                  # this folder in VS Code
cmd.exe /c <command>    # run a Windows command
```

- **Networking:** a server on `localhost:3000` in WSL opens at
  `http://localhost:3000` in your Windows browser, and the other way round.
- **Line endings:** Windows tools may save files with CRLF, which breaks
  shell scripts (`bad interpreter`). Set
  `git config --global core.autocrlf input`, edit with Linux-aware tools,
  and fix stray files with `dos2unix <file>` (`sudo apt install dos2unix`).

## 6. VS Code

1. Install VS Code **on Windows** from <https://code.visualstudio.com/download>.
2. Install the **WSL** extension (`ms-vscode-remote.remote-wsl`).
3. In a project folder in Ubuntu, run `code .`. The first run installs VS
   Code's server into WSL.

Extensions that work on your code (linters, language servers, debuggers)
must be installed in WSL: in the Extensions view, click **Install in WSL**.

## 7. Git and GitHub

```bash
git config --global user.name "First Last"
git config --global user.email "you@example.com"
git config --global init.defaultBranch main
```

SSH key for GitHub (use GitHub's
[Linux instructions](https://docs.github.com/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)
for details):

```bash
ssh-keygen -t ed25519 -C "you@example.com"
cat ~/.ssh/id_ed25519.pub     # add it at GitHub → Settings → SSH keys
ssh -T git@github.com         # check
```

Clone into `~` (e.g. `~/repos`), never `/mnt/c`.

## 8. Languages

**Node.js** with [nvm](https://github.com/nvm-sh/nvm) (several versions side
by side, no `sudo` for global packages; check its README for the latest
version):

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.8/install.sh | bash
# open a new terminal, then:
nvm install --lts
```

**Java and Kotlin** with [SDKMAN!](https://sdkman.io/):

```bash
sudo apt install -y zip unzip
curl -s "https://get.sdkman.io" | bash
# open a new terminal, then:
sdk list java                 # pick a current identifier, e.g. a Temurin LTS
sdk install java <identifier>
sdk install kotlin && sdk install gradle && sdk install maven
```

**Python** with [uv](https://docs.astral.sh/uv/) (projects, dependencies and
Python versions in one tool; leave Ubuntu's own Python to the system):

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
# open a new terminal, then:
uv init myproject && cd myproject
uv add requests
uv run python
```

**Homebrew** also [works on Linux](https://docs.brew.sh/Homebrew-on-Linux)
for tools apt doesn't carry; keep apt as the default.

## 9. When Something Goes Wrong

| Symptom | Try |
|---------|-----|
| WSL hangs or misbehaves | `wsl --shutdown` (PowerShell), then reopen Ubuntu |
| `.wslconfig` changes ignored | `wsl --shutdown` |
| A distro won't start | `wsl --list --verbose`, then `wsl --terminate <distro>` |
| `code .` not found | reinstall VS Code's WSL extension, or start VS Code once from Windows |
| git, npm or builds are slow | move the project from `/mnt/c` to `~` |
| Script fails with `bad interpreter` | CRLF line endings: `dos2unix <file>` |

`wsl --shutdown` stops **every** distro, and Docker Desktop's WSL backend
with them.

- **Docker:** use Docker Desktop with **Settings → Resources → WSL
  Integration** enabled for your distro.
- **Disk space:** WSL's virtual disk grows but doesn't shrink on its own.
  Run `wsl --shutdown`, then `wsl --manage Ubuntu --set-sparse true` in an
  elevated PowerShell.

## 10. Coming from macOS

| macOS | WSL2 Ubuntu |
|-------|-------------|
| `brew install` | `sudo apt install` (Homebrew works too) |
| zsh, `~/.zshrc` | the same, once you switch (§4); start a fresh `~/.zshrc`, don't copy your Mac's |
| `open .` | `explorer.exe .` |
| `pbcopy` / `pbpaste` | `clip.exe` / `powershell.exe Get-Clipboard` (see below) |
| BSD `sed -i ''`, `ls -G` | GNU `sed -i`, `ls --color=auto`; `date`, `find`, `stat` flags differ too |
| case-insensitive files | **case-sensitive**: `./MyFile` and `./myfile` are different |
| `/Users/you` | `/home/you` |
| Cmd+C / Cmd+V in the terminal | Ctrl+Shift+C / Ctrl+Shift+V |

`clip.exe` garbles non-ASCII text, and `Get-Clipboard` adds Windows line
endings. These versions avoid both (add them to `~/.zshrc`):

```bash
pbcopy()  { { printf '\377\376'; iconv -f UTF-8 -t UTF-16LE; } | clip.exe; }
pbpaste() { powershell.exe -NoProfile -Command '[Console]::OutputEncoding = [Text.Encoding]::UTF8; [Console]::Write((Get-Clipboard -Raw))' | tr -d '\r'; }
alias open='explorer.exe'
```

## Further Reading

- [WSL documentation](https://learn.microsoft.com/windows/wsl/) and
  [basic commands](https://learn.microsoft.com/windows/wsl/basic-commands)
- [VS Code in WSL](https://code.visualstudio.com/docs/remote/wsl)
- [nvm](https://github.com/nvm-sh/nvm), [SDKMAN!](https://sdkman.io/),
  [uv](https://docs.astral.sh/uv/), [Homebrew on Linux](https://docs.brew.sh/Homebrew-on-Linux)
