#!/usr/bin/env python3
"""Apply a theme to Windows Terminal and Windows (wsl2-dev:theme).

    windows.py [--dry-run] [--quiet] [--no-terminal] [--windows]

Run by `theme`, which passes the theme in environment variables (THEME_ID,
TERM_*, OS_*; see the theme files). This:

  1. Windows Terminal (unless --no-terminal): adds or updates the theme's
     color scheme in settings.json and sets it on this distro's profile
     (named $WSL_DISTRO_NAME; every WSL profile if none is). The first change
     saves the original as settings.json.before-theme.
  2. Windows (only with --windows): dark/light mode and the accent color
     (HKCU registry). The first change exports the original keys to
     ~/.local/state/wsl2-dev/theme/windows-backup/. The taskbar and Start
     pick up the accent after you sign out (or restart Explorer).
"""

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

WIN = Path("/mnt/c/Windows/System32")
STATE = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "wsl2-dev" / "theme"

ANSI_KEYS = ["black", "red", "green", "yellow", "blue", "purple", "cyan", "white",
             "brightBlack", "brightRed", "brightGreen", "brightYellow",
             "brightBlue", "brightPurple", "brightCyan", "brightWhite"]

PERSONALIZE = r"HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
ACCENT = r"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent"
DWM = r"HKCU\Software\Microsoft\Windows\DWM"

dry_run = "--dry-run" in sys.argv
quiet = "--quiet" in sys.argv
terminal = "--no-terminal" not in sys.argv
windows = "--windows" in sys.argv


def say(msg):
    if not quiet or dry_run:
        print(msg)


def env(name):
    try:
        return os.environ[name]
    except KeyError:
        sys.exit(f"theme: {name} isn't set (run this through the theme command)")


def win(exe, *args):
    """Run a Windows program from a Windows directory (avoids UNC cwd warnings)."""
    out = subprocess.run([str(WIN / exe), *args], cwd="/mnt/c", capture_output=True)
    return out.returncode, out.stdout.decode("utf-8", "replace").replace("\r", "")


# --- Windows Terminal --------------------------------------------------------

def terminal_settings():
    _, local = win("cmd.exe", "/c", "echo %LOCALAPPDATA%")
    local = Path(subprocess.run(["wslpath", local.strip()], capture_output=True,
                                text=True, check=True).stdout.strip())
    found = list(local.glob("Packages/Microsoft.WindowsTerminal*_8wekyb3d8bbwe/LocalState/settings.json"))
    found += list(local.glob("Microsoft/Windows Terminal/settings.json"))  # unpackaged install
    return found


def is_wsl_profile(profile):
    source = profile.get("source", "")
    return (source in ("Windows.Terminal.Wsl", "Microsoft.WSL")
            or source.startswith("CanonicalGroupLimited")
            or "wsl" in profile.get("commandline", "").lower())


def own_profiles(profiles):
    """This distro's profiles; all WSL profiles if none is named after it."""
    wsl = [p for p in profiles if is_wsl_profile(p)]
    # \\wsl.localhost\<distro>\ when WSL_DISTRO_NAME didn't make it here (e.g. tmux)
    distro = os.environ.get("WSL_DISTRO_NAME") or subprocess.run(
        ["wslpath", "-w", "/"], capture_output=True, text=True).stdout.strip("\\\n").split("\\")[-1]
    return [p for p in wsl if p.get("name") == distro] or wsl


def apply_terminal():
    ansi = env("TERM_ANSI_LIST").split()
    scheme = {"name": env("TERM_SCHEME"), "background": env("TERM_BG"),
              "foreground": env("TERM_FG"), "cursorColor": env("TERM_CURSOR"),
              "selectionBackground": env("TERM_SELECTION"), **dict(zip(ANSI_KEYS, ansi))}

    paths = terminal_settings()
    if not paths:
        say("Windows Terminal: no settings.json found; set the color scheme by hand.")
    for path in paths:
        try:
            settings = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            say(f"Windows Terminal: {path} isn't plain JSON (comments?); set "
                f"'{scheme['name']}' by hand.")
            continue

        changes = []
        schemes = settings.setdefault("schemes", [])
        old = next((s for s in schemes if s.get("name") == scheme["name"]), None)
        if old is None:
            schemes.append(scheme)
            changes.append(f"add scheme '{scheme['name']}'")
        elif {k: str(v).lower() for k, v in old.items()} != {k: v.lower() for k, v in scheme.items()}:
            old.clear()
            old.update(scheme)
            changes.append(f"update scheme '{scheme['name']}'")

        for profile in own_profiles(settings.get("profiles", {}).get("list", [])):
            if profile.get("colorScheme") != scheme["name"]:
                changes.append(f"profile '{profile.get('name')}': "
                               f"{profile.get('colorScheme', '(default)')} -> {scheme['name']}")
                profile["colorScheme"] = scheme["name"]

        if not changes:
            say(f"Windows Terminal: already '{scheme['name']}'.")
            continue
        for change in changes:
            say(f"Windows Terminal: {change}")
        if dry_run:
            continue
        backup = path.with_name(path.name + ".before-theme")
        if not backup.exists():
            shutil.copy2(path, backup)
        path.write_text(json.dumps(settings, indent=4, ensure_ascii=False) + "\n", encoding="utf-8")


# --- Windows -----------------------------------------------------------------

def rgb(color):
    return tuple(int(color[i:i + 2], 16) for i in (1, 3, 5))


def mix(color, target, amount):
    return tuple(round(c + (t - c) * amount) for c, t in zip(color, target))


def abgr(color):
    r, g, b = color
    return 0xFF000000 | b << 16 | g << 8 | r


def reg_value(key, name):
    code, out = win("reg.exe", "query", key, "/v", name)
    if code != 0:
        return None
    for line in out.splitlines():
        parts = line.split()
        if len(parts) >= 3 and parts[0] == name:
            return parts[2]
    return None


def reg_set(key, name, kind, data):
    old = reg_value(key, name)
    new = f"0x{data:x}" if kind == "REG_DWORD" else data
    if old is not None and old.lower() == new.lower():
        return False
    say(f"Windows: {key.rsplit(chr(92), 1)[-1]}\\{name}: {old} -> {new}")
    if not dry_run:
        code, out = win("reg.exe", "add", key, "/v", name, "/t", kind, "/d", new, "/f")
        if code != 0:
            sys.exit(f"theme: reg add {key} {name} failed: {out.strip()}")
    return True


def backup_registry():
    folder = STATE / "windows-backup"
    if dry_run or folder.exists():
        return
    folder.mkdir(parents=True)
    for key in (PERSONALIZE, ACCENT, DWM):
        target = folder / (key.rsplit("\\", 1)[-1] + ".reg")
        win("reg.exe", "export", key,
            subprocess.run(["wslpath", "-w", str(target)], capture_output=True,
                           text=True, check=True).stdout.strip(), "/y")
    say(f"Windows: saved the original settings to {folder}")


def apply_windows():
    light = 1 if env("OS_APPEARANCE") == "light" else 0
    accent = rgb(env("OS_ACCENT"))
    white, black = (255, 255, 255), (0, 0, 0)
    # Windows' 8 accent shades: 3 lighter, the accent, 3 darker, and a spare
    # that's kept as is
    shades = [mix(accent, white, a) for a in (0.65, 0.45, 0.25)] + [accent] + \
             [mix(accent, black, a) for a in (0.26, 0.45, 0.69)]
    old_palette = reg_value(ACCENT, "AccentPalette") or ""
    spare = old_palette[56:64] if len(old_palette) == 64 else "00000000"
    palette = "".join(f"{r:02X}{g:02X}{b:02X}00" for r, g, b in shades) + spare

    backup_registry()
    changed = [
        reg_set(PERSONALIZE, "AppsUseLightTheme", "REG_DWORD", light),
        reg_set(PERSONALIZE, "SystemUsesLightTheme", "REG_DWORD", light),
        reg_set(ACCENT, "AccentPalette", "REG_BINARY", palette),
        reg_set(ACCENT, "AccentColorMenu", "REG_DWORD", abgr(accent)),
        reg_set(ACCENT, "StartColorMenu", "REG_DWORD", abgr(shades[4])),
        reg_set(DWM, "AccentColor", "REG_DWORD", abgr(accent)),
        reg_set(DWM, "ColorizationColor", "REG_DWORD", 0xC4000000 | int(env("OS_ACCENT")[1:], 16)),
        reg_set(DWM, "ColorizationAfterglow", "REG_DWORD", 0xC4000000 | int(env("OS_ACCENT")[1:], 16)),
    ]
    if not any(changed):
        say(f"Windows: already {env('OS_APPEARANCE')} mode, accent {env('OS_ACCENT')}.")
    elif not dry_run:
        say("Windows: sign out and back in (or restart Explorer) to update the taskbar and Start.")


if __name__ == "__main__":
    if terminal:
        apply_terminal()
    if windows:
        apply_windows()
