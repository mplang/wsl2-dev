# wsl2-dev:theme -- sourced by ~/.bashrc and ~/.zshrc
#
# Loads the current theme's shell colors (LS_COLORS, bat, autosuggestions)
# and fzf colors, and reloads them at the next prompt after a `theme` switch.

_wsl2dev_theme_dir=${XDG_CONFIG_HOME:-$HOME/.config}/wsl2-dev/theme
if [ ! -r "$_wsl2dev_theme_dir/env.sh" ] && command -v theme >/dev/null 2>&1; then
    theme --apply --no-terminal --quiet || true
fi
[ -r "$_wsl2dev_theme_dir/fzfrc" ] && export FZF_DEFAULT_OPTS_FILE="$_wsl2dev_theme_dir/fzfrc"

_wsl2dev_theme_reload() {
    local mtime
    mtime=$(stat -c %Y "$_wsl2dev_theme_dir/env.sh" 2>/dev/null) || return 0
    [ "$mtime" = "${_wsl2dev_theme_mtime:-}" ] && return 0
    _wsl2dev_theme_mtime=$mtime
    . "$_wsl2dev_theme_dir/env.sh"
    # zsh's completion lists use LS_COLORS too
    [ -n "${ZSH_VERSION:-}" ] && eval 'zstyle ":completion:*" list-colors ${(s.:.)LS_COLORS}'
    return 0
}
_wsl2dev_theme_reload

if [ -n "${ZSH_VERSION:-}" ]; then
    autoload -Uz add-zsh-hook && add-zsh-hook precmd _wsl2dev_theme_reload
elif [ -n "${BASH_VERSION:-}" ]; then
    case ";${PROMPT_COMMAND[*]-};" in
        *_wsl2dev_theme_reload*) ;;
        *) PROMPT_COMMAND="_wsl2dev_theme_reload${PROMPT_COMMAND:+;$PROMPT_COMMAND}" ;;
    esac
fi
