# Developing on WSL2 (Ubuntu)

[Windows Subsystem for Linux](https://learn.microsoft.com/windows/wsl/about) 2 ("WSL2") lets you run a full Linux environment directly on Windows: no dual-booting, no manually provisioned virtual machines. For developers, it means you get Linux-native toolchains, package managers, and runtimes while keeping the Windows desktop you already work in.

This guide walks through installing WSL2, configuring it sensibly, wiring up VS Code, and setting up common development stacks (Git, Node.js, Java/Kotlin, Python, Docker), and keeping your distro backed up and current.

> **Conventions in this guide**
> - Commands prefixed with nothing are run in your **Ubuntu** shell.
> - Commands explicitly called out as **PowerShell** are run in a Windows PowerShell or Command Prompt.
> - Replace placeholder values (usernames, paths, versions) with your own.
> - This guide standardizes on **zsh** as the shell (set up in [§6](#standardize-on-zsh-recommended)). Shell-specific references – e.g., the `~/.zshrc` profile – assume you've made that switch.

---

## 1. Before You Begin

- **Windows version:** WSL2 requires Windows 10 version 2004 (Build 19041) or later, or any version of Windows 11. Install all available Windows updates first.
- **Virtualization:** WSL2 runs on a lightweight VM, so hardware virtualization must be enabled. Open **Task Manager → Performance → CPU** and confirm "Virtualization: Enabled." If it is disabled, enable it in your BIOS/UEFI firmware.
- **Corporate/managed machines:** If your device is managed by an organization, endpoint-security or antivirus software can occasionally interfere with the virtualization features WSL2 depends on. If installation fails in a way the troubleshooting section doesn't cover, check with your IT department.

---

## 2. Install WSL2

Modern WSL installs with a single command. Open **PowerShell as Administrator** and run:

```powershell
wsl --install
```

This enables the required Windows features, installs the WSL2 kernel, sets WSL2 as the default version, and installs **Ubuntu** (the default distribution). **Reboot when prompted.**

After rebooting, Ubuntu will launch (or launch it from the Start menu) and prompt you to create a **Linux username and password**. This account is separate from your Windows account; the password is what you'll use for `sudo`.

### Useful variations

```powershell
wsl --list --online           # See all distributions available to install
wsl --install -d Ubuntu-24.04 # Install a specific distribution/version
wsl --install --no-launch     # Install without auto-launching
wsl --install --web-download  # Install from the online source instead of the Microsoft Store
```

> **On older or locked-down Windows:** If `wsl --install` only prints usage text, or the Store is blocked, use `wsl --install --inbox` to install WSL via the Windows component (updates then arrive through Windows Update). On Windows 10 you may also need the `-d` flag to specify a distribution. See Microsoft's [manual installation steps](https://learn.microsoft.com/windows/wsl/install-manual) if you need full control.

### Confirm your setup

```powershell
wsl --version                 # WSL, kernel, and WSLg versions
wsl --list --verbose          # Installed distros, their state, and WSL version (should say "2")
```

---

## 3. Windows Terminal (Recommended)

[Windows Terminal](https://learn.microsoft.com/windows/terminal/) ships with Windows 11 and is the recommended way to work with your Ubuntu shell. It supports tabs, panes, and per-profile configuration.

**Make Ubuntu your default profile and start in your Linux home directory:**

1. Open Windows Terminal → **Settings** (`Ctrl+,`).
2. Set **Default profile** to **Ubuntu**.
3. Select the **Ubuntu** profile → **General** → set **Starting directory**. By default Terminal drops you in your Windows home folder (mounted at `/mnt/c/Users/<you>`), which you want to avoid for real work. Set it to your Linux home:
   - Either clear the field so it uses the distro default, or
   - Set it explicitly to `\\wsl.localhost\Ubuntu\home\<your-linux-username>`.

---

## 4. Configure WSL (Optional)

WSL works without any configuration, but two files let you change how it behaves:

| File | Where | Applies to |
|------|-------|------------|
| `.wslconfig` | your **Windows** home folder, e.g. `C:\Users\<you>\.wslconfig` | the WSL virtual machine, so every distro |
| `/etc/wsl.conf` | inside the distro (edit with `sudo`) | that distro only |

Changes take effect the next time WSL starts: run `wsl --shutdown` in **PowerShell**, then reopen Ubuntu. On Windows 11, the **WSL Settings** app (in the Start menu) edits `.wslconfig` for you and explains each setting.

### `.wslconfig`: resources, networking, and disk

Windows manages WSL2's resources automatically, but on resource-constrained machines WSL2 can be greedier than you'd like. A reasonable starting point:

```ini
[wsl2]
# Cap WSL's memory and CPUs (defaults: half of Windows' memory, all CPUs)
memory=8GB
processors=4
# Share Windows' network interfaces (Windows 11 22H2 or later; see below)
networkingMode=mirrored

[experimental]
# New virtual disks give space back to Windows when you delete files
sparseVhd=true
```

- **`memory` and `processors`:** adjust to your hardware.
- **`networkingMode=mirrored`** gives Linux the same network interfaces as Windows instead of a separate virtual network. `localhost` then works reliably in both directions, IPv6 works, other devices on your network can reach a server running in WSL (you may need a Windows Firewall rule), and many VPNs that break WSL's default networking start working. If you have no networking trouble, the default (`nat`) is fine.
- **`sparseVhd=true`** affects only distros created after you set it. For an existing one, see [Reclaiming disk space](#reclaiming-disk-space).

### `/etc/wsl.conf`: per-distro settings

```bash
sudo nano /etc/wsl.conf
```

Ubuntu's file already has a few lines; keep them, and add the sections you want:

```ini
[boot]
# Already set on recent Ubuntu installs; services such as Docker Engine need it
systemd=true

[automount]
# Let chmod and chown work on Windows files under /mnt/c
options="metadata"

[interop]
# Keep Windows' PATH out of Linux's PATH (see below)
appendWindowsPath=false
```

- **`systemd`** runs Linux's normal service manager, so services start the way they do on any Ubuntu machine. `ps -p 1 -o comm=` prints `systemd` when it's on.
- **`metadata`:** without it, every file under `/mnt/c` shows the same permissions and `chmod` silently does nothing. You only need it if you keep files on the Windows side (which §5 advises against for code).
- **`appendWindowsPath=false`:** WSL normally appends every directory on your Windows `PATH` to Linux's. That's what makes `code` and `explorer.exe` work, but it also makes every failed command lookup (tab completion, typos, zsh's command suggestions) search all of those Windows directories, which is slow. If your shell feels sluggish, turn it off and add back only the Windows directories you use, in `~/.zshrc`:

  ```bash
  # VS Code's default per-user install location, plus explorer.exe, clip.exe, cmd.exe and powershell.exe
  export PATH="$PATH:/mnt/c/Users/<you>/AppData/Local/Programs/Microsoft VS Code/bin:/mnt/c/Windows:/mnt/c/Windows/System32:/mnt/c/Windows/System32/WindowsPowerShell/v1.0"
  ```

---

## 5. Understand the Filesystem (Important)

This is the single most important concept for working productively in WSL2.

WSL2 gives each distribution its own native Linux **ext4** filesystem inside a virtual disk, mounted at the Linux root (`/`). Your Linux home directory is `/home/<your-linux-username>`, shortcut `~`.

> **Keep your source code on the Linux filesystem (under `~`).** This is where you should do essentially all of your development work.

### Crossing the divide

- **Access Linux files from Windows:** use the `\\wsl.localhost` network path, e.g. `\\wsl.localhost\Ubuntu\home\<your-linux-username>` (the older `\\wsl$` form works too). Pin it to **Quick access** in Explorer for one-click access. You can also run `explorer.exe .` from inside a Linux directory to open it in Windows Explorer.
- **Access Windows files from Linux:** your `C:` drive is mounted at `/mnt/c`, so everything on Windows is reachable from Linux.

### Why location matters for performance

Crossing the Windows/Linux boundary goes through a translation layer. Working on files stored under `/mnt/c` **from Linux** (or on `\\wsl.localhost` files **from Windows tools**) is dramatically slower, and for large, many-file operations like `git status` or `npm install`, it can be unacceptably slow. Keeping your repos on the native Linux filesystem avoids this entirely.

> **Caution:** Avoid using Windows applications to *write* to the `\\wsl.localhost` filesystem. A Windows-native Git client operating on Linux-backed files, for example, is likely to cause problems. Read-only Windows tools are generally fine, but your mileage may vary.

### A few Linux basics

| Command | What it does |
|---------|--------------|
| `pwd` | Print the current directory's absolute path |
| `cd ~` | Change to your home directory (`~` always expands to it) |
| `ls` | List directory contents |
| `ls -alh` | Long format, including hidden files, with human-readable sizes |

The directory separator in Linux is the forward slash (`/`).

---

## 6. Orienting Yourself in Linux

If you're comfortable developing but new to Linux (or haven't lived in it day-to-day), here's the quick translation of concepts you already know into their Ubuntu forms.

### The mental model

- Your shell is **Bash** out of the box – the command interpreter, analogous to PowerShell or `cmd` but with a different (POSIX) command vocabulary. This guide switches to **zsh** (see [Standardize on zsh](#standardize-on-zsh-recommended) below), a drop-in-compatible shell with better interactive ergonomics.
- There is **no "Program Files" and no per-app installer wizard** for most things. You install software through a **package manager**, `apt`, which resolves dependencies and keeps everything updatable from one place.
- `apt` operations that modify the system require **root** privileges, so you prefix them with `sudo` ("do as superuser"). You'll be asked for the Linux password you created at setup, not your Windows password.

```bash
sudo apt update                 # Refresh the list of available packages
sudo apt install <package>      # Install something
sudo apt remove <package>       # Remove it
apt search <term>               # Find a package by keyword
```

### Survival commands

You likely know the equivalents; these are the names and the flags worth memorizing.

| Command | Purpose | Notes |
|---------|---------|-------|
| `cat <file>` | Print a file | `less <file>` to page through; `q` to quit |
| `mkdir -p a/b/c` | Make directories | `-p` creates parents as needed |
| `cp` / `mv` / `rm` | Copy / move / remove | `rm -r` for directories; **there is no recycle bin** |
| `find . -name '*.ts'` | Find files | |
| `grep -r "text" .` | Search file contents | Recursive from current dir |
| `man <command>` | Read the manual | The authoritative reference for any command |
| `<command> --help` | Quick usage | Shorter than `man` for most tools |

A few shell ergonomics: **Tab** completes paths and commands; **Ctrl+R** searches your command history; **Ctrl+C** interrupts the running process; **Ctrl+L** (or `clear`) clears the screen; the up/down arrows walk history.

### Standardize on zsh (recommended)

Ubuntu ships with Bash, but this guide standardizes on **zsh** – it's largely Bash-compatible, and its interactive niceties (smarter tab-completion, better history, path expansion) make day-to-day work more pleasant. Do this switch **now**, before installing the language tools below, so their initializers land in the right profile.

```bash
sudo apt install zsh -y     # Install zsh
zsh --version               # Confirm
chsh -s $(which zsh)        # Make it your default login shell
```

The `chsh` change takes effect on your next login, so **close and reopen your Ubuntu terminal**. The first time zsh starts it runs a configuration wizard – you can pick the defaults and move on; it writes an initial `~/.zshrc` for you.

**Oh My Zsh (Optional).** [Oh My Zsh](https://ohmyz.sh/) is a popular community framework for managing zsh configuration, with themes and plugins (git shortcuts, autosuggestions, syntax highlighting). It's entirely optional, but a nice quality-of-life layer:

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

### Your shell profile: `~/.zshrc`

`~/.zshrc` is the script zsh runs for each new interactive shell. It's where your `PATH`, aliases, environment variables, and tool initializers (nvm, SDKMAN!, etc.) live – the same role Bash's `~/.bashrc` plays, and conceptually identical to a PowerShell profile. After editing it, either open a new shell or re-run it in place:

```bash
source ~/.zshrc
```

> Installers in this guide (nvm, SDKMAN!) detect zsh and append their setup to `~/.zshrc` automatically, which is why you switched shells first.

### File permissions and the execute bit

Every file carries permissions for its owner, group, and others (read/write/execute). The one that surprises newcomers most often: a script won't run until it's marked **executable**.

```bash
chmod +x script.sh     # Add the execute bit
./script.sh            # Run it (the ./ is required for scripts in the current dir)
ls -l                  # The leading rwx--- field shows current permissions
```

If you hit a "Permission denied" running something you just wrote, the missing execute bit is the usual cause.

---

## 7. Windows ↔ WSL Interop

WSL2 is a real Linux VM, not an emulation layer, but Microsoft has stitched the two worlds together so you can reach across the boundary easily.

### Calling across the divide

From your **Ubuntu** shell you can invoke Windows executables directly (note the `.exe`):

```bash
explorer.exe .          # Open the current Linux directory in Windows Explorer
code .                  # Open the current directory in VS Code (Windows side)
clip.exe < file.txt     # Pipe output into the Windows clipboard
cmd.exe /c <command>    # Run a Windows command
```

Windows automatically puts your Windows `PATH` on the Linux `PATH`, which is why `.exe`s are reachable. (If this ever causes collisions, it can be disabled in `/etc/wsl.conf`.)

### Networking and `localhost`

For most development this just works: a server you start inside WSL on, say, port 3000 is reachable from Windows at `http://localhost:3000`, and vice versa. That means your browser on Windows can hit a dev server running in Linux with no extra configuration. (Some advanced setups bind only to the loopback interface or use mirrored networking – worth knowing the term if you ever need to dig in, but the default behavior is transparent.)

### Line endings (CRLF vs LF)

Windows tools historically write files with CRLF (`\r\n`) line endings; Linux expects LF (`\n`). A file saved with CRLF can break shell scripts in Linux with cryptic errors (a script that "exists and is executable" but fails with `bad interpreter` or `command not found` is the textbook symptom – the stray `\r` is the culprit).

Guidance:

- Keep your repos on the Linux filesystem and edit them with Linux-aware tools (VS Code via the WSL extension handles this correctly).
- Configure Git to not rewrite endings on you. On WSL, the common setting is:

  ```bash
  git config --global core.autocrlf input
  ```

  This checks out as-is and commits LF, which is what you want when the code runs in Linux.
- If a file already has the wrong endings, `dos2unix <file>` (install with `sudo apt install dos2unix`) fixes it.

---

## 8. Visual Studio Code on WSL2

VS Code integrates with WSL2 so well that it's the recommended editor. With the **WSL** extension, VS Code runs a lightweight server inside your Linux distribution – it's fully aware your source lives on the Linux filesystem, integrates with Linux-side Git and tooling, and makes the Windows/Linux divide seamless.

### Install

1. Install the **Windows** build of VS Code: <https://code.visualstudio.com/download>. (Install it on Windows, not inside Ubuntu.)
2. Install the **WSL** extension (`ms-vscode-remote.remote-wsl`) from the Extensions sidebar. VS Code often prompts to install it automatically the first time it detects WSL.

> **Note:** This extension was formerly called "Remote - WSL." It is now simply "**WSL**." If you want SSH and Dev Containers too, install the **Remote Development** extension pack, which bundles all three.

### Open a project

**From the Ubuntu shell (easiest):**

```bash
cd ~/repos/my-project
code .
```

The first time you run `code`, it will install the VS Code server into WSL automatically.

**From within VS Code:**

1. Open the Command Palette (`Ctrl+Shift+P`) and search for **WSL**, or click the remote indicator (`><`) in the bottom-left corner.
2. Choose **WSL: Open Folder in WSL…** and select your project.

### Extensions in WSL

Some extensions (themes, keybindings) run on the Windows UI side; others (linters, language servers, debuggers) must be installed **inside** WSL. When connected to a WSL folder, the Extensions sidebar shows a separate **WSL** section. For any extension that needs to run against your code, click **Install in WSL: Ubuntu**.

---

## 9. Set Up Git

Git comes preinstalled on Ubuntu; you just need to configure it. Do this **inside WSL**, and keep your clones under your Linux home directory.

### Minimum configuration

```bash
git config --global user.name "First Last"
git config --global user.email "you@example.com"
git config --global init.defaultBranch main
```

### GitHub authentication over SSH

Generate a key inside WSL and add it to your GitHub account. Follow GitHub's guide and be sure to use the **Linux** instructions:
<https://docs.github.com/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent>

Quick version:

```bash
ssh-keygen -t ed25519 -C "you@example.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub   # Copy this and add it to GitHub → Settings → SSH keys
ssh -T git@github.com       # Verify
```

You're now set to clone repositories. Put them somewhere under `~` (e.g., `~/repos`).

> **Tip:** an agent started with `eval "$(ssh-agent -s)"` lasts only for that terminal. To share one agent across all your terminals (and type your key's passphrase once per WSL session), install [keychain](https://www.funtoo.org/Funtoo:Keychain) with `sudo apt install keychain` and add this to `~/.zshrc`:
>
> ```bash
> eval "$(keychain --eval --quiet id_ed25519)"
> ```

---

## 10. Development Stacks

### 10.1 Keeping Ubuntu and WSL Up to Date

System and package updates in Ubuntu are straightforward. Run periodically (enter your password if prompted):

```bash
sudo apt update && sudo apt upgrade -y
```

WSL itself (its kernel and the `wsl` command) updates separately. Check for updates from **PowerShell** now and then:

```powershell
wsl --update
```

### 10.2 Homebrew (Optional)

Some tools are easiest to install with [Homebrew](https://docs.brew.sh/Homebrew-on-Linux), which works on Linux the same way it does on macOS. The native `apt` is still the recommended default for most packages, but Homebrew is a fine complement for tools not well packaged in `apt`.

Install it, then follow the installer's "Next steps" output to add `brew` to your `PATH`. To update Homebrew-managed packages:

```bash
brew update && brew upgrade
```

### 10.3 Node.js (via nvm)

For JavaScript/TypeScript work, install Node.js with [nvm](https://github.com/nvm-sh/nvm) rather than from `apt` – it lets you install and switch between Node versions per project, and avoids permission headaches with global installs.

```bash
# Install nvm (check the repo for the latest version string).
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.8/install.sh | bash

# The installer appends its setup to ~/.zshrc. Restart your shell
# (or `source ~/.zshrc`), then:
nvm install --lts      # Install the latest LTS Node
nvm use --lts
node --version         # Verify
```

### 10.4 Java and Kotlin (via SDKMAN!)

Use [SDKMAN!](https://sdkman.io/) to install and manage Java, Kotlin, Maven, Gradle, and more. The big win is that you avoid hand-wiring a JDK installation and `JAVA_HOME`, and you can install and switch between versions trivially.

**Prerequisites:** update Ubuntu (§10.1) and install `zip`/`unzip`:

```bash
sudo apt install zip unzip -y
```

**Install SDKMAN!** following the (non-Windows) instructions at <https://sdkman.io/install>, then open a new shell or run `source "$HOME/.sdkman/bin/sdkman-init.sh"`.

**Install a JDK.** List what's available, then install a current LTS (Java 25 is the latest LTS as of this writing; 21 and 17 are also supported LTS releases):

```bash
sdk list java            # Browse available vendors/versions and their identifiers
sdk install java         # Installs SDKMAN!'s recommended default, or...
sdk install java 25-tem  # ...pick a specific identifier, e.g. a Temurin 25 build
sdk current java         # Verify the active version
```

> The exact version identifiers (e.g., `25-tem`, `21.0.4-tem`) change over time. Always run `sdk list java` to get a valid, current identifier rather than copying a version string verbatim.

**Install Kotlin, Maven, and Gradle:**

```bash
sdk install kotlin
sdk install maven
sdk install gradle
```

Switch versions at any time with `sdk use java <identifier>`, or set a default with `sdk default java <identifier>`.

### 10.5 Python (via uv)

Ubuntu comes with Python 3, but leave that one to the system. For your own projects, [uv](https://docs.astral.sh/uv/) does the jobs of pip, venv and pyenv in one fast tool: it creates projects, manages their dependencies with a lock file, and installs whichever Python version a project needs.

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh   # Install uv (open a new shell after)
uv init myproject && cd myproject                  # A new project
uv add requests                                    # Add a dependency (creates .venv)
uv run python                                      # Run something in the project's environment
```

### 10.6 GPU Computing (CUDA)

WSL2 can use your Windows machine's NVIDIA GPU for CUDA work such as machine learning, but the setup differs from a regular Linux machine:

- Install or update the NVIDIA driver **on Windows** only. WSL makes it available to Linux automatically; `nvidia-smi` in Ubuntu should list your GPU.
- **Never install an NVIDIA Linux driver inside WSL.** It replaces the one WSL provides and breaks GPU access.
- If you need the CUDA toolkit, follow NVIDIA's [CUDA on WSL guide](https://docs.nvidia.com/cuda/wsl-user-guide/): use its **WSL-Ubuntu** installer or a `cuda-toolkit-*` package, never the `cuda` or `cuda-drivers` packages, which bring a driver with them. Many frameworks (PyTorch, for example) ship their own CUDA libraries, so you may not need the toolkit at all.

---

## 11. Docker

There are two good ways to run Docker with WSL2. Both give you the same `docker` and `docker compose` commands in your Ubuntu shell; they differ in where the engine runs and what it costs.

| | Docker Desktop | Docker Engine in WSL |
|-|----------------|----------------------|
| What it is | A Windows app that runs the engine in its own WSL distro and connects your distros to it | Docker's Linux packages, installed directly in your Ubuntu distro |
| Cost | Free for personal use, education, non-commercial open source, and small businesses; larger companies need a [paid subscription](https://www.docker.com/pricing/) | Free and open source |
| Extras | Dashboard GUI, Kubernetes, extensions, Windows containers, automatic updates | The engine and command-line tools; updates come with `apt` |
| Across distros | One engine, with the same images and containers, serves every distro you enable | Each distro has its own engine, images, and containers |
| Overhead | Its own background processes and distro | Only what Docker itself uses |

**Which to choose:** if your organization provides Docker Desktop, or you want the GUI or Kubernetes, use Docker Desktop. If you only need containers from the command line, or Docker Desktop's license doesn't fit, Docker Engine in WSL is lighter and free. Either way, **use one per distro**: Docker Desktop's integration and a Docker Engine installed in the same distro conflict.

### Option A: Docker Desktop

1. Install [Docker Desktop for Windows](https://docs.docker.com/desktop/setup/install/windows-install/) and keep the **WSL 2** backend it offers (the default).
2. In Docker Desktop → **Settings → Resources → WSL Integration**, turn on integration for your distro (it's on for your default distro already) and click **Apply**.
3. Open a new Ubuntu terminal and check:

   ```bash
   docker run hello-world
   ```

Docker Desktop must be running for `docker` to work in WSL. If the command is missing or can't connect, check that Docker Desktop is running and that integration is on for this distro. `wsl --shutdown` also stops Docker Desktop's engine and all its containers; Docker Desktop offers to restart it.

### Option B: Docker Engine in WSL

Docker Engine runs as a system service, so it needs systemd, which recent Ubuntu installs have on by default (see [§4](#etcwslconf-per-distro-settings); `ps -p 1 -o comm=` should print `systemd`).

Install it from Docker's own apt repository. These steps follow Docker's [Ubuntu instructions](https://docs.docker.com/engine/install/ubuntu/); check there for changes. (Ubuntu's own `docker.io` package works too, but lags behind.)

```bash
# Remove conflicting packages, if any are installed
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt remove $pkg; done

# Add Docker's repository
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
sudo apt update

# Install Docker Engine, the CLI, Buildx, and Compose
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

To use `docker` without `sudo`, add yourself to the `docker` group, then open a new terminal (or run `newgrp docker`):

```bash
sudo usermod -aG docker $USER
docker run hello-world    # Verify
```

> **Security:** membership in the `docker` group is equivalent to root access in this distro. That's usually acceptable on a personal development machine, but it's worth knowing.

Docker starts with the distro, and containers run only while the distro does: `wsl --shutdown` stops them. Ports you publish (`docker run -p 8080:80 ...`) are reachable from Windows at `http://localhost:8080`.

### Either way

- Keep project files, and anything you bind-mount into a container (`-v ./src:/app`), on the Linux filesystem (§5). Mounting from `/mnt/c` is slow.
- VS Code's **Dev Containers** extension works with both options.
- Images, containers, and volumes take up disk space: `docker system df` shows how much, and `docker system prune` removes what's unused. To give the space back to Windows, see [Reclaiming disk space](#reclaiming-disk-space).

---

## 12. Back Up, Move, and Upgrade Your Distro

### Back up

Windows backup tools such as OneDrive and File History cover your Windows folders, **not your Linux files**: the whole distro lives in a single virtual disk file under `AppData`, which they don't include. Push your code to a remote often, and take an occasional full snapshot from **PowerShell**:

```powershell
wsl --shutdown
wsl --export Ubuntu D:\Backups\ubuntu-backup.tar
```

To restore, import the backup as a new distro (choose any name and folder):

```powershell
wsl --import Ubuntu-restored D:\WSL\Ubuntu-restored D:\Backups\ubuntu-backup.tar
wsl -d Ubuntu-restored
```

If the restored distro signs you in as `root`, set your user with `wsl --manage Ubuntu-restored --set-default-user <your-linux-username>`.

### Move to another drive

A distro's virtual disk lives on `C:` by default. To move it, from **PowerShell**:

```powershell
wsl --shutdown
wsl --manage Ubuntu --move D:\WSL\Ubuntu
```

If `--move` isn't recognized, run `wsl --update` first.

### Upgrade to a new Ubuntu release

There are two ways. Take a backup first either way.

**In place.** This upgrades the distro you have; everything stays where it is:

```bash
sudo apt update && sudo apt full-upgrade -y
sudo do-release-upgrade
```

An LTS release is offered the next LTS once that release's first point update (e.g. 26.04.1) is out.

**Side by side.** Install the new release as a separate distro, move in, and remove the old one when you no longer need it. It takes longer, but you start clean and the old distro stays available as a fallback. From **PowerShell**:

```powershell
wsl --list --online             # Find the new release's name
wsl --install -d Ubuntu-26.04
```

Then, in the **new** distro, copy what you need straight from the old one (here named `Ubuntu`; `wsl.exe --list` shows the names):

```bash
wsl.exe -d Ubuntu --cd '~' -- tar -c .ssh .gitconfig | tar -C ~ -x
```

Add any other files or folders to the list. For repositories, push everything from the old distro and clone fresh, or copy them the same way. Make the new distro your default in Windows Terminal (§3) and for the `wsl` command (`wsl --set-default Ubuntu-26.04`). When you're sure you have everything, remove the old one:

```powershell
wsl --unregister Ubuntu         # Permanently deletes the distro and all its files
```

---

## 13. Troubleshooting, Tips, and Tricks

### Restart WSL2

Many transient WSL2 problems are solved by restarting it. From **PowerShell** or **Command Prompt**:

```powershell
wsl --shutdown
```

> **Note:** Shutting down WSL2 terminates **all** running distros and WSL terminals – and, if you use Docker Desktop's WSL2 backend, the Docker engine and all running containers. Docker Desktop will prompt you to restart its backend; click **Restart**.

Relaunch Ubuntu from the Start menu or Windows Terminal to bring it back up.

### Reclaiming disk space

The WSL2 virtual disk grows as you use it but does not automatically shrink. If it's consuming too much space after you've deleted large files, you can compact it. Shut WSL down first (`wsl --shutdown`), then from an elevated PowerShell:

```powershell
wsl --manage Ubuntu --set-sparse true
```

To see what's using the space, `sudo apt install ncdu` and run `ncdu ~` (or `docker system df` for Docker's share).

For older WSL builds, you can compact the `.vhdx` manually with `diskpart`'s `compact vdisk` — search Microsoft's docs for your version if the command above isn't available.

### Common fixes at a glance

| Symptom | Try |
|---------|-----|
| WSL feels broken or hung | `wsl --shutdown`, then relaunch |
| `.wslconfig` changes not applied | `wsl --shutdown`, then relaunch |
| Distro won't start / corrupted | `wsl --list --verbose`, then `wsl --terminate <distro>` |
| `code .` not found | Run once from the Windows side, or reinstall the WSL extension; if you set `appendWindowsPath=false`, add VS Code to `PATH` (§4) |
| Slow Git/npm/builds | Confirm your repo is under `~`, **not** under `/mnt/c` |
| Need to see WSL/kernel versions | `wsl --version` |
| No network or DNS inside WSL, often on a VPN | Try `networkingMode=mirrored` ([§4](#wslconfig-resources-networking-and-disk)), then `wsl --shutdown` |
| `docker` not found or can't connect | See [§11](#11-docker) for your setup |

---

## 14. Coming from macOS

If you've spent years on a Mac, WSL2 Ubuntu will feel *almost* like home – which is exactly what makes the differences sneaky. macOS and Linux are both Unix-like, so most of your instincts transfer, but a handful of details will bite you. Here's the translation table.

### Package management

`apt` is your `brew`. It's the native, recommended way to install software, and it needs `sudo`:

```bash
sudo apt install ripgrep        # ≈ brew install ripgrep
```

Homebrew itself also runs on Linux ([Homebrew on Linux](https://docs.brew.sh/Homebrew-on-Linux)) if you want the muscle memory and the larger formula selection for dev tools – see §10.2. A common pattern is `apt` for system packages and `brew` for developer tooling.

### The shell

macOS has defaulted to **zsh** since Catalina, and this guide standardizes on zsh too (set up in §6), so you're back on home ground. Ubuntu's out-of-the-box default is Bash, but once you've made the switch your shell is zsh again. A few caveats:

- Your profile is `~/.zshrc`, same filename as on your Mac, but start it fresh. Don't copy your macOS `~/.zshrc` wholesale; it likely references Homebrew paths, `pbcopy`/`pbpaste`, and other macOS-isms that don't exist here (see the aliases below to bridge the common ones).
- Oh My Zsh, plugins, and themes all work identically. Reinstall them in WSL rather than copying the macOS install.

### Clipboard and "open"

The macOS conveniences have WSL equivalents rather than native ones:

| macOS | WSL2 | 
|-------|------|
| `pbcopy` | `clip.exe` (e.g., `cat file \| clip.exe`) |
| `pbpaste` | `powershell.exe Get-Clipboard` |
| `open .` | `explorer.exe .` |

If the muscle memory is strong, define them in `~/.zshrc`. Plain aliases to `clip.exe` and `Get-Clipboard` have rough edges (`clip.exe` garbles non-ASCII text, and `Get-Clipboard` adds Windows line endings), so these small functions convert the text on the way through:

```bash
pbcopy()  { { printf '\377\376'; iconv -f UTF-8 -t UTF-16LE; } | clip.exe; }
pbpaste() { powershell.exe -NoProfile -Command '[Console]::OutputEncoding = [Text.Encoding]::UTF8; [Console]::Write((Get-Clipboard -Raw))' | tr -d '\r'; }
alias open='explorer.exe'
```

`explorer.exe` understands `.` and Windows paths, but not other Linux paths; `cd` into a folder and run `open .` instead.

### GNU vs BSD coreutils

macOS ships **BSD** versions of `sed`, `awk`, `ls`, `date`, `find`, etc.; Linux ships **GNU** versions. They differ in flags and behavior, and this is the classic source of "the command I've typed for a decade now behaves differently":

- **`sed -i`**: BSD requires an argument (`sed -i '' 's/a/b/' f`); GNU does not (`sed -i 's/a/b/' f`). Scripts written on a Mac often break here, and vice versa.
- **`ls` colors**: `ls -G` on BSD; `ls --color=auto` on GNU.
- **`date`**: flag syntax for relative dates differs entirely.
- **`xargs`, `find`, `stat`**: assorted flag differences.

The upside: scripts you write on WSL target GNU coreutils, which is what the vast majority of Linux CI runners and containers use, so your local environment now *matches production* more closely than macOS did.

### Case sensitivity

The default macOS filesystem (APFS) is **case-insensitive**; the Linux ext4 filesystem is **case-sensitive**. `import './MyComponent'` will happily resolve `mycomponent.ts` on a Mac and then fail in CI or on WSL. Moving to Linux often surfaces latent case bugs.

### Paths and home

- Your home is `/home/<you>`, not `/Users/<you>`. `~` and `$HOME` work as expected.
- There's no `/Applications`; GUI apps aren't how you think about Linux dev tooling.
- Keybinding muscle memory: in the terminal it's **Ctrl**, not **Cmd** (Ctrl+C, Ctrl+R, etc.). Copy/paste in Windows Terminal is typically Ctrl+Shift+C / Ctrl+Shift+V, or configurable.

### What stays the same

SSH keys, `git`, Node/nvm, SDKMAN!, Docker workflows, and the general Unix shell experience all behave as you'd expect. The conceptual leap from macOS to WSL2 is small.

---

## 15. Further Reading

- WSL documentation: <https://learn.microsoft.com/windows/wsl/>
- WSL basic commands reference: <https://learn.microsoft.com/windows/wsl/basic-commands>
- VS Code in WSL: <https://code.visualstudio.com/docs/remote/wsl>
- WSL configuration (`.wslconfig`, `wsl.conf`): <https://learn.microsoft.com/windows/wsl/wsl-config>
- Docker Desktop's WSL 2 backend: <https://docs.docker.com/desktop/features/wsl/>
- Docker Engine on Ubuntu: <https://docs.docker.com/engine/install/ubuntu/>
- CUDA on WSL: <https://docs.nvidia.com/cuda/wsl-user-guide/>
- Homebrew on Linux: <https://docs.brew.sh/Homebrew-on-Linux>
- SDKMAN!: <https://sdkman.io/>
- nvm: <https://github.com/nvm-sh/nvm>
- uv: <https://docs.astral.sh/uv/>
