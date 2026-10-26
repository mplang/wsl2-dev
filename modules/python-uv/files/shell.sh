# wsl2-dev:python-uv -- sourced by ~/.bashrc and ~/.zshrc

. "${XDG_CONFIG_HOME:-$HOME/.config}/wsl2-dev/python-uv/direnv-hook.sh"

# Tab completion for uv and uvx. Generating it takes a few hundred
# milliseconds, so it's cached and regenerated only when uv changes.
_wsl2dev_uv=$(command -v uv 2>/dev/null)
if [ -n "$_wsl2dev_uv" ]; then
    if [ -n "${ZSH_VERSION:-}" ]; then _wsl2dev_sh=zsh; else _wsl2dev_sh=bash; fi
    _wsl2dev_cache=${XDG_CACHE_HOME:-$HOME/.cache}/wsl2-dev/uv-completion.$_wsl2dev_sh
    if [ ! -s "$_wsl2dev_cache" ] || [ "$_wsl2dev_uv" -nt "$_wsl2dev_cache" ]; then
        mkdir -p "${_wsl2dev_cache%/*}"
        { uv generate-shell-completion "$_wsl2dev_sh"; uvx --generate-shell-completion "$_wsl2dev_sh"; } \
            > "$_wsl2dev_cache" 2>/dev/null
    fi
    if [ -n "${ZSH_VERSION:-}" ]; then
        (( ${+functions[compdef]} )) || { autoload -Uz compinit && compinit; }
    fi
    . "$_wsl2dev_cache"
fi
unset _wsl2dev_uv _wsl2dev_sh _wsl2dev_cache
