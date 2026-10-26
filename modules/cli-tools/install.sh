#!/usr/bin/env bash
# install.sh -- cli-tools: bat, lsd, eza, ripgrep and glow, with aliases
#
#   ./install.sh              install or update
#   ./install.sh --dry-run    show what would change
#   ./install.sh --uninstall  remove the aliases (the packages stay)
#
# Installs the packages with apt (asking first), links bat to batcat, and
# hooks ~/.config/wsl2-dev/cli-tools/shell.sh into ~/.bashrc and ~/.zshrc,
# whichever exist. See README.md.

MODULE=cli-tools
source "$(dirname "$0")/../../lib/common.sh"
parse_args "$@"
require_wsl

PACKAGES=(bat lsd eza ripgrep glow)
BAT_LINK=$BIN_DIR/bat
HOOK='[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/wsl2-dev/cli-tools/shell.sh" ] && . "${XDG_CONFIG_HOME:-$HOME/.config}/wsl2-dev/cli-tools/shell.sh"'
mapfile -t RCS < <(shell_rcs)

if ((UNINSTALL)); then
    say "Removing $MODULE:"
    for rc in "${RCS[@]}"; do remove_hook "$rc" "#"; done
    remove_file "$CONFIG_DIR/shell.sh"
    remove_dir "$CONFIG_DIR"
    if [[ -L $BAT_LINK && $(readlink "$BAT_LINK") == /usr/bin/batcat ]]; then
        step "remove the $(pretty "$BAT_LINK") link" rm -f "$BAT_LINK"
    fi
    say "Done. The packages are still installed (sudo apt remove ${PACKAGES[*]})."
    exit 0
fi

check_free "$CONFIG_DIR/shell.sh"
say "Installing $MODULE:"

# Older Ubuntu releases lack some of these; install what apt has
available=() missing=()
for pkg in "${PACKAGES[@]}"; do
    if [[ -n $(apt-cache policy "$pkg" 2>/dev/null | sed -n 's/^ *Candidate: //p' | grep -v '(none)') ]]; then
        available+=("$pkg")
    else
        missing+=("$pkg")
    fi
done
apt_install "${available[@]}"
((${#missing[@]})) && say "  not in this Ubuntu's apt: ${missing[*]} (see README.md for other ways)"

# Debian and Ubuntu install bat as batcat
if [[ -L $BAT_LINK && $(readlink "$BAT_LINK") == /usr/bin/batcat ]]; then
    say "  $(pretty "$BAT_LINK") links to batcat"
elif command -v bat >/dev/null; then
    :   # a bat command already exists
elif [[ -x /usr/bin/batcat ]] || ((DRY_RUN)); then
    step "link $(pretty "$BAT_LINK") to /usr/bin/batcat" \
        sh -c 'mkdir -p "$1" && ln -s /usr/bin/batcat "$2"' _ "$BIN_DIR" "$BAT_LINK"
fi

install_file "$MODULE_DIR/files/shell.sh" "$CONFIG_DIR/shell.sh" 644
if ((${#RCS[@]})); then
    for rc in "${RCS[@]}"; do add_hook "$rc" "#" "$HOOK"; done
else
    say "  no ~/.bashrc or ~/.zshrc found; source $(pretty "$CONFIG_DIR/shell.sh") from your shell's startup file"
fi
say "Done. Open a new terminal, then try: ll   lt   bat README.md   rg TODO"
warn_path
