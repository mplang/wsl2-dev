#!/usr/bin/env bash
# install.sh -- git: WSL-friendly git settings
#
#   ./install.sh              install or update
#   ./install.sh --dry-run    show what would change
#   ./install.sh --uninstall  remove it
#
# Writes ~/.config/wsl2-dev/git/config for this machine and includes it at
# the top of ~/.gitconfig, so your own settings there still win. See
# README.md.

MODULE=git
source "$(dirname "$0")/../../lib/common.sh"
parse_args "$@"
require_wsl

GITCONFIG=$HOME/.gitconfig
CONF=$CONFIG_DIR/config

# Windows' Git Credential Manager, as Git for Windows installs it: ucrt64
# from 2.56, mingw64 before, clangarm64 on ARM. (A standalone GCM also needs
# WSLENV set in Windows, so it isn't picked up here.)
gcm=
for toolchain in ucrt64 mingw64 clangarm64; do
    candidate=$(wslpath -u "C:\\Program Files\\Git\\$toolchain\\bin\\git-credential-manager.exe" 2>/dev/null) || continue
    [[ -x $candidate ]] && { gcm=$candidate; break; }
done

# render FILE: this machine's settings
render() {
    local f=$1
    local g=(git config --file "$f")
    printf '%s\n' "# $TAG -- included at the top of ~/.gitconfig: settings there win." \
        "# Written by modules/git/install.sh for this machine; edits here are lost" \
        "# on the next install. Put your own settings in ~/.gitconfig." > "$f"

    # Line endings: commit LF, never convert on checkout (code runs in Linux)
    "${g[@]}" core.autocrlf input
    "${g[@]}" init.defaultBranch main
    # Better diffs, and conflicts that show the common ancestor
    "${g[@]}" diff.algorithm histogram
    if printf '%s\n%s\n' 2.35 "$(git version | awk '{print $3}')" | sort -V -C; then
        "${g[@]}" merge.conflictstyle zdiff3
    else
        "${g[@]}" merge.conflictstyle diff3    # zdiff3 needs git 2.35+
    fi
    "${g[@]}" rerere.enabled true          # remember how you resolved a conflict
    # Pull rebases your local commits instead of making merge commits
    "${g[@]}" pull.rebase true
    "${g[@]}" rebase.updateRefs true
    "${g[@]}" fetch.prune true             # forget branches deleted on the remote
    # git push on a new branch creates it on the remote
    "${g[@]}" push.default current
    "${g[@]}" push.autoSetupRemote true
    "${g[@]}" branch.sort -committerdate   # git branch: recent first

    if command -v code >/dev/null; then
        "${g[@]}" diff.tool vscode
        "${g[@]}" difftool.vscode.cmd 'code --wait --diff "$LOCAL" "$REMOTE"'
        "${g[@]}" merge.tool vscode
        "${g[@]}" mergetool.vscode.cmd 'code --wait --merge "$REMOTE" "$LOCAL" "$BASE" "$MERGED"'
        "${g[@]}" mergetool.vscode.trustExitCode true
    fi
    if [[ -n $gcm ]]; then
        # git runs the helper through the shell, so escape the spaces
        "${g[@]}" credential.helper "${gcm// /\\ }"
        "${g[@]}" credential.https://dev.azure.com.useHttpPath true
    fi
}

if ((UNINSTALL)); then
    say "Removing $MODULE:"
    remove_hook "$GITCONFIG" "#"
    remove_file "$CONF"
    remove_dir "$CONFIG_DIR"
    say "Done."
    exit 0
fi

require_cmd git
check_free "$CONF"
say "Installing $MODULE:"
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
render "$tmp"
install_file "$tmp" "$CONF" 644
HOOK_POSITION=top add_hook "$GITCONFIG" "#" "[include]" "	path = $CONF"

command -v code >/dev/null && say "  VS Code is the diff and merge tool (git difftool, git mergetool)" \
    || say "  VS Code's 'code' command wasn't found, so no diff/merge tool was set"
[[ -n $gcm ]] && say "  HTTPS remotes sign in through Windows' Git Credential Manager" \
    || say "  Git Credential Manager wasn't found (install Git for Windows for HTTPS sign-in; see README.md)"
for key in user.name user.email; do
    git config --global --get "$key" >/dev/null || say "Note: set your $key: git config --global $key \"...\""
done
say "Done."
