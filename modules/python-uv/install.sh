#!/usr/bin/env bash
# install.sh -- python-uv: Python projects with uv, activated by direnv
#
#   ./install.sh              install or update
#   ./install.sh --dry-run    show what would change
#   ./install.sh --uninstall  remove it
#
# Installs uv (to ~/.local/bin) and direnv (apt), adds `layout uv` for
# direnv, and hooks ~/.config/wsl2-dev/python-uv/shell.sh (direnv, uv
# completion) into ~/.bashrc and ~/.zshrc, whichever exist. See README.md.

MODULE=python-uv
source "$(dirname "$0")/../../lib/common.sh"
parse_args "$@"
require_wsl

DIRENV_LIB=${XDG_CONFIG_HOME:-$HOME/.config}/direnv/lib/wsl2-dev-uv.sh
HOOK='[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/wsl2-dev/python-uv/shell.sh" ] && . "${XDG_CONFIG_HOME:-$HOME/.config}/wsl2-dev/python-uv/shell.sh"'
mapfile -t RCS < <(shell_rcs)

if ((UNINSTALL)); then
    say "Removing $MODULE:"
    for rc in "${RCS[@]}"; do remove_hook "$rc" "#"; done
    remove_file "$CONFIG_DIR/shell.sh"
    remove_file "$CONFIG_DIR/direnv-hook.sh"
    remove_dir "$CONFIG_DIR"
    remove_file "$DIRENV_LIB"
    say "Done. uv and direnv stay installed (README.md says how to remove uv)."
    exit 0
fi

check_free "$CONFIG_DIR/shell.sh" "$CONFIG_DIR/direnv-hook.sh" "$DIRENV_LIB"
say "Installing $MODULE:"
apt_install direnv curl
if command -v uv >/dev/null || [[ -x $BIN_DIR/uv ]]; then
    say "  uv is installed ($("${BIN_DIR}/uv" --version 2>/dev/null || uv --version); update with: uv self update)"
else
    # Astral's installer; UV_NO_MODIFY_PATH: it would otherwise edit shell rc files
    step "install uv to $(pretty "$BIN_DIR")" \
        sh -c 'curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="$1" UV_NO_MODIFY_PATH=1 sh -s -- --quiet' _ "$BIN_DIR"
fi
install_file "$MODULE_DIR/files/shell.sh" "$CONFIG_DIR/shell.sh" 644
install_file "$MODULE_DIR/files/direnv-hook.sh" "$CONFIG_DIR/direnv-hook.sh" 644
install_file "$MODULE_DIR/files/direnv-uv.sh" "$DIRENV_LIB" 644
for rc in "${RCS[@]}"; do add_hook "$rc" "#" "$HOOK"; done
((${#RCS[@]})) || say "  no ~/.bashrc or ~/.zshrc found; source $(pretty "$CONFIG_DIR/shell.sh") from your shell's startup file"

say "Done. Open a new terminal, then:"
say "  uv init myproject && cd myproject && echo 'layout uv' > .envrc && direnv allow"
warn_path
