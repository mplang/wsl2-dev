# wsl2-dev:python-uv -- sourced by ~/.bashrc and ~/.zshrc

. "${XDG_CONFIG_HOME:-$HOME/.config}/wsl2-dev/python-uv/direnv-hook.sh"

# Tab completion for uv and uvx
if command -v uv >/dev/null 2>&1; then
    if [ -n "${ZSH_VERSION:-}" ]; then
        (( ${+functions[compdef]} )) || { autoload -Uz compinit && compinit; }
        eval "$(uv generate-shell-completion zsh)"
        eval "$(uvx --generate-shell-completion zsh)"
    elif [ -n "${BASH_VERSION:-}" ]; then
        eval "$(uv generate-shell-completion bash)"
        eval "$(uvx --generate-shell-completion bash)"
    fi
fi
