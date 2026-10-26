# lib/common.sh -- helpers shared by modules/*/install.sh. Sourced, not run.
#
# A module's install.sh sets MODULE, sources this file, calls parse_args "$@",
# then uses the functions below. Every change goes through them, so
# --dry-run and --uninstall behave the same in every module.

set -euo pipefail

: "${MODULE:?set MODULE before sourcing common.sh}"
MODULE_DIR=$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)
CONFIG_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/wsl2-dev/$MODULE
BIN_DIR=$HOME/.local/bin
# Every installed file contains this tag, so uninstall only removes our files
TAG="wsl2-dev:$MODULE"

DRY_RUN=0
UNINSTALL=0

usage() {
    sed -n '2,/^$/{s/^# \{0,1\}//;p}' "${BASH_SOURCE[2]:-$0}"
    exit "${1:-0}"
}

parse_args() {
    while (($#)); do
        case $1 in
            --dry-run)   DRY_RUN=1 ;;
            --uninstall) UNINSTALL=1 ;;
            -h|--help)   usage ;;
            *)  # a module can take more options by defining module_option
                if declare -F module_option >/dev/null && module_option "$1"; then :
                else echo "unknown option: $1" >&2; usage 1 >&2; fi ;;
        esac
        shift
    done
    ((DRY_RUN)) && say "Dry run: nothing will be changed."
    return 0
}

say() { printf '%s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

# step DESCRIPTION COMMAND [ARGS...]: report a change and make it (unless
# this is a dry run)
step() {
    local what=$1; shift
    if ((DRY_RUN)); then say "  would $what"; else say "  $what"; "$@"; fi
}

# ~/path for messages
pretty() { printf '%s' "${1/#$HOME/\~}"; }

require_wsl() {
    grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null \
        || die "this module is for WSL; this doesn't look like WSL"
}

require_cmd() {
    local cmd
    for cmd; do
        command -v "$cmd" >/dev/null || die "$cmd is required; install it first"
    done
}

# confirm QUESTION: ask yes/no (Enter means yes); no when not interactive
confirm() {
    [[ -t 0 ]] || return 1
    local answer
    read -rp "  $1 [Y/n] " answer
    [[ ${answer:-y} == [Yy]* ]]
}

# apt_install PACKAGE...: install the ones that are missing, after asking
apt_install() {
    local pkg missing=()
    for pkg; do
        dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q 'ok installed' \
            || missing+=("$pkg")
    done
    ((${#missing[@]})) || return 0
    # for testing installers without sudo
    if [[ -n ${WSL2DEV_SKIP_APT:-} ]]; then say "  skipping apt (WSL2DEV_SKIP_APT): ${missing[*]}"; return 0; fi
    if ((DRY_RUN)); then say "  would install with apt: ${missing[*]}"; return 0; fi
    [[ -t 0 ]] || die "missing packages: ${missing[*]} (run: sudo apt install ${missing[*]})"
    read -rp "  Install ${missing[*]} with sudo apt? [Y/n] " answer
    [[ ${answer:-y} == [Yy]* ]] || die "cancelled; install ${missing[*]} and run this again"
    sudo apt-get install -y "${missing[@]}"
}

# backup_once FILE: keep the original as FILE.wsl2-dev.bak (first change only)
backup_once() {
    [[ -e $1 && ! -e $1.wsl2-dev.bak ]] || return 0
    step "back up $(pretty "$1") to $(pretty "$1").wsl2-dev.bak" cp -p "$1" "$1.wsl2-dev.bak"
}

# install_file SOURCE DEST MODE: copy a module file into place. Refuses to
# replace a file that isn't ours (no TAG in it).
install_file() {
    local src=$1 dest=$2 mode=$3
    if [[ -e $dest ]]; then
        if cmp -s "$src" "$dest"; then say "  $(pretty "$dest") is up to date"; return 0; fi
        grep -qF "$TAG" "$dest" \
            || die "$(pretty "$dest") exists and isn't from $TAG; move it aside first"
        step "update $(pretty "$dest")" install -m "$mode" "$src" "$dest"
    else
        step "install $(pretty "$dest")" install -D -m "$mode" "$src" "$dest"
    fi
}

# check_free FILE...: before installing, make sure none of FILEs belongs to
# someone else, so a refusal never leaves a half-done install
check_free() {
    local file foreign=()
    for file; do
        [[ -e $file ]] && ! grep -qF "$TAG" "$file" && foreign+=("$(pretty "$file")")
    done
    ((${#foreign[@]})) || return 0
    die "these already exist and aren't from $TAG; move them aside first: ${foreign[*]}"
}

# remove_file FILE: remove a file this module installed
remove_file() {
    local file=$1
    [[ -e $file ]] || return 0
    if grep -qF "$TAG" "$file"; then
        step "remove $(pretty "$file")" rm -f "$file"
    else
        say "  keeping $(pretty "$file"): it isn't from $TAG"
    fi
}

# remove_dir DIR: remove the module's config folder if nothing else is in it
remove_dir() {
    [[ -d $1 ]] || return 0
    step "remove $(pretty "$1")" rmdir --ignore-fail-on-non-empty "$1"
    # and ~/.config/wsl2-dev once the last module is gone
    local parent=${1%/*}
    if [[ ${parent##*/} == wsl2-dev && -d $parent ]] && ! ((DRY_RUN)); then
        rmdir --ignore-fail-on-non-empty "$parent"
    fi
}

_strip_block() {    # FILE COMMENT: print FILE without this module's block
    awk -v begin="$2 >>> $TAG >>>" -v end="$2 <<< $TAG <<<" '
        $0 == begin { skip = 1; next }
        $0 == end   { skip = 0; next }
        !skip' "$1"
}

# _write FILE TEXT: replace FILE's contents in place (follows symlinks, keeps
# permissions). TEXT is built in memory first, never streamed from FILE.
_write() { printf '%s\n' "$2" > "$1"; }

# add_hook FILE COMMENT LINE...: put LINEs in FILE between this module's
# markers (COMMENT is the file's comment string, e.g. "#" or "\""). Replaces
# an outdated block where it is; leaves an identical one alone. A new block
# goes at the end, or at the top with HOOK_POSITION=top (for frameworks that
# must load before everything else). Creates FILE if needed.
add_hook() {
    local file=$1 comment=$2; shift 2
    local block current="" rest=""
    block=$(printf '%s >>> %s >>>\n' "$comment" "$TAG"; printf '%s\n' "$@"
            printf '%s <<< %s <<<' "$comment" "$TAG")
    if [[ -e $file ]]; then
        current=$(awk -v begin="$comment >>> $TAG >>>" -v end="$comment <<< $TAG <<<" '
            $0 == begin { on = 1 } on { print } $0 == end { on = 0 }' "$file")
        if [[ $current == "$block" ]]; then
            say "  $(pretty "$file") is already hooked up"; return 0
        fi
        backup_once "$file"
        if [[ -n $current ]]; then
            # replace it where it is, in case the user moved it on purpose
            step "update the $TAG block in $(pretty "$file")" _write "$file" "$(
                BLOCK=$block awk -v begin="$comment >>> $TAG >>>" -v end="$comment <<< $TAG <<<" '
                    $0 == begin { print ENVIRON["BLOCK"]; skip = 1; next }
                    $0 == end   { skip = 0; next }
                    !skip' "$file")"
            return 0
        fi
        rest=$(cat "$file")
        while [[ $rest == *$'\n' ]]; do rest=${rest%$'\n'}; done
    fi
    local verb="add the $TAG block to"
    if [[ -n $rest && ${HOOK_POSITION:-bottom} == top ]]; then
        step "$verb the top of $(pretty "$file")" _write "$file" "$block"$'\n\n'"$rest"
    elif [[ -n $rest ]]; then
        step "$verb $(pretty "$file")" _write "$file" "$rest"$'\n\n'"$block"
    else
        step "$verb $(pretty "$file")" _write "$file" "$block"
    fi
}

# remove_hook FILE COMMENT: take this module's block out of FILE
remove_hook() {
    local file=$1 comment=$2 rest
    [[ -e $file ]] && grep -qxF "$comment >>> $TAG >>>" "$file" || return 0
    rest=$(_strip_block "$file" "$comment")
    while [[ $rest == *$'\n' ]]; do rest=${rest%$'\n'}; done
    step "remove the $TAG block from $(pretty "$file")" _write "$file" "$rest"
}

# shell_rcs: the interactive shell startup files that exist (bash and zsh)
shell_rcs() {
    local rc
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do [[ -e $rc ]] && printf '%s\n' "$rc"; done
    return 0
}

warn_path() {
    case ":$PATH:" in
        *":$BIN_DIR:"*) ;;
        *) say "Note: $(pretty "$BIN_DIR") isn't on your PATH yet. Ubuntu adds it at login once it"
           say "      exists; open a new terminal (or add it to PATH in your shell config)." ;;
    esac
}
