#!/usr/bin/env bash
# install.sh -- tmux: terminal multiplexer config for Windows Terminal
#
#   ./install.sh              install or update
#   ./install.sh --dry-run    show what would change
#   ./install.sh --uninstall  remove it
#
# Installs tmux (apt) and hooks ~/.config/wsl2-dev/tmux/tmux.conf into the
# top of ~/.tmux.conf (your settings below it win), and plugins.conf (TPM)
# into the end. See README.md.

MODULE=tmux
source "$(dirname "$0")/../../lib/common.sh"
parse_args "$@"
require_wsl

# tmux reads ~/.tmux.conf, or ~/.config/tmux/tmux.conf when that doesn't exist
TMUXCONF=$HOME/.tmux.conf
XDG_TMUXCONF=${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf
[[ ! -e $TMUXCONF && -e $XDG_TMUXCONF ]] && TMUXCONF=$XDG_TMUXCONF
TOP_HOOK="source-file $(pretty "$CONFIG_DIR")/tmux.conf"
END_HOOK="source-file $(pretty "$CONFIG_DIR")/plugins.conf"
END_TAG=wsl2-dev:tmux-plugins

# Reload a running tmux, but only one that loaded this config file
reload() {
    command -v tmux >/dev/null || return 0
    local loaded
    loaded=$(tmux display -p '#{config_files}' 2>/dev/null) || return 0
    [[ ,$loaded, == *",$TMUXCONF,"* ]] || return 0
    step "reload the running tmux" tmux source-file "$TMUXCONF"
}

if ((UNINSTALL)); then
    say "Removing $MODULE:"
    remove_hook "$TMUXCONF" "#"
    TAG=$END_TAG remove_hook "$TMUXCONF" "#"
    remove_file "$CONFIG_DIR/tmux.conf"
    remove_file "$CONFIG_DIR/plugins.conf"
    remove_dir "$CONFIG_DIR"
    say "Done. Restart tmux (tmux kill-server) to drop the settings. The plugins stay in ~/.tmux/plugins."
    exit 0
fi

check_free "$CONFIG_DIR/tmux.conf" "$CONFIG_DIR/plugins.conf"
say "Installing $MODULE:"
apt_install tmux git
install_file "$MODULE_DIR/files/tmux.conf" "$CONFIG_DIR/tmux.conf" 644
install_file "$MODULE_DIR/files/plugins.conf" "$CONFIG_DIR/plugins.conf" 644
HOOK_POSITION=top add_hook "$TMUXCONF" "#" "$TOP_HOOK"
TAG=$END_TAG add_hook "$TMUXCONF" "#" "$END_HOOK"
reload
say "Done. Start tmux with: tmux   (the first start installs the plugins)"
