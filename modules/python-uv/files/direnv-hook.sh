# wsl2-dev:python-uv -- loaded by shell.sh
#
# direnv: load a project's .envrc when you cd into it. Shared by wsl2-dev's
# python-uv and node-nvm modules; hooks in only once, and not if something
# else (e.g. oh-my-zsh's direnv plugin) already did.
if command -v direnv >/dev/null 2>&1; then
    if [ -n "${ZSH_VERSION:-}" ]; then
        case " ${precmd_functions[*]-} " in
            *" _direnv_hook "*) ;;
            *) eval "$(direnv hook zsh)" ;;
        esac
    elif [ -n "${BASH_VERSION:-}" ]; then
        case ";${PROMPT_COMMAND[*]-};" in
            *_direnv_hook*) ;;
            *) eval "$(direnv hook bash)" ;;
        esac
    fi
fi
