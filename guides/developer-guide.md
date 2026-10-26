# Developing on WSL2 (Ubuntu)

[Windows Subsystem for Linux](https://learn.microsoft.com/windows/wsl/about) 2 ("WSL2") lets you run a full Linux environment directly on Windows: no dual-booting, no manually provisioned virtual machines. For developers, it means you get Linux-native toolchains, package managers, and runtimes while keeping the Windows desktop you already work in.

This guide walks through installing WSL2, configuring it sensibly, wiring up VS Code, and setting up common development stacks (Git, Node.js, Java/Kotlin).

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
   - Set it explicitly to `\\wsl$\Ubuntu\home\<your-linux-username>`.

---

## 4. Configure Resource Usage (Optional)

Windows manages WSL2's resources automatically, but on resource-constrained machines WSL2 can be greedier than you'd like. You can cap it with a `.wslconfig` file in your **Windows** home folder (e.g., `C:\Users\<you>\.wslconfig`):

```ini
[wsl2]
memory=8GB
processors=4
```

Adjust the values to suit your hardware. Apply changes by restarting WSL (see [Troubleshooting](#11-troubleshooting-tips-and-tricks)).

---

## 5. Understand the Filesystem (Important)

This is the single most important concept for working productively in WSL2.

WSL2 gives each distribution its own native Linux **ext4** filesystem inside a virtual disk, mounted at the Linux root (`/`). Your Linux home directory is `/home/<your-linux-username>`, shortcut `~`.

> **Keep your source code on the Linux filesystem (under `~`).** This is where you should do essentially all of your development work.

### Crossing the divide

- **Access Linux files from Windows:** use the `\\wsl$` network path, e.g. `\\wsl$\Ubuntu\home\<your-linux-username>`. You can also run `explorer.exe .` from inside a Linux directory to open it in Windows Explorer.
- **Access Windows files from Linux:** your `C:` drive is mounted at `/mnt/c`, so everything on Windows is reachable from Linux.

### Why location matters for performance

Crossing the Windows/Linux boundary goes through a translation layer. Working on files stored under `/mnt/c` **from Linux** (or on `\\wsl$` files **from Windows tools**) is dramatically slower, and for large, many-file operations like `git status` or `npm install`, it can be unacceptably slow. Keeping your repos on the native Linux filesystem avoids this entirely.

> **Caution:** Avoid using Windows applications to *write* to the `\\wsl$` filesystem. A Windows-native Git client operating on Linux-backed files, for example, is likely to cause problems. Read-only Windows tools are generally fine, but your mileage may vary.

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

---

## 10. Development Stacks

### 10.1 Keeping Ubuntu Up to Date

System and package updates in Ubuntu are straightforward. Run periodically (enter your password if prompted):

```bash
sudo apt update && sudo apt upgrade -y
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
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

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

---

## 11. Troubleshooting, Tips, and Tricks

### Restart WSL2

Many transient WSL2 problems are solved by restarting it. From **PowerShell** or **Command Prompt**:

```powershell
wsl --shutdown
```

> **Note:** Shutting down WSL2 terminates **all** running distros and WSL terminals – and, if you use Docker Desktop's WSL2 backend, the Docker engine and all running containers. Docker Desktop will prompt you to restart its backend; click **Restart**.

Relaunch Ubuntu from the Start menu or Windows Terminal to bring it back up.

### Docker

If you want Docker inside WSL2, the simplest path is **Docker Desktop** with WSL2 integration enabled (Docker Desktop → **Settings → Resources → WSL Integration**). If you hit Docker-related issues, first confirm Docker Desktop is running and that integration is enabled for your distro.

### Reclaiming disk space

The WSL2 virtual disk grows as you use it but does not automatically shrink. If it's consuming too much space after you've deleted large files, you can compact it. Shut WSL down first (`wsl --shutdown`), then from an elevated PowerShell:

```powershell
wsl --manage Ubuntu --set-sparse true
```

For older WSL builds, you can compact the `.vhdx` manually with `diskpart`'s `compact vdisk` — search Microsoft's docs for your version if the command above isn't available.

### Common fixes at a glance

| Symptom | Try |
|---------|-----|
| WSL feels broken or hung | `wsl --shutdown`, then relaunch |
| `.wslconfig` changes not applied | `wsl --shutdown`, then relaunch |
| Distro won't start / corrupted | `wsl --list --verbose`, then `wsl --terminate <distro>` |
| `code .` not found | Run once from the Windows side, or reinstall the WSL extension |
| Slow Git/npm/builds | Confirm your repo is under `~`, **not** under `/mnt/c` |
| Need to see WSL/kernel versions | `wsl --version` |

---

## 12. Coming from macOS

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

If the muscle memory is strong, alias them in `~/.zshrc`:

```bash
alias pbcopy='clip.exe'
alias pbpaste='powershell.exe Get-Clipboard'
alias open='explorer.exe'
```

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

## 13. Further Reading

- WSL documentation: <https://learn.microsoft.com/windows/wsl/>
- WSL basic commands reference: <https://learn.microsoft.com/windows/wsl/basic-commands>
- VS Code in WSL: <https://code.visualstudio.com/docs/remote/wsl>
- Homebrew on Linux: <https://docs.brew.sh/Homebrew-on-Linux>
- SDKMAN!: <https://sdkman.io/>
- nvm: <https://github.com/nvm-sh/nvm>
