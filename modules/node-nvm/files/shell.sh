# wsl2-dev:node-nvm -- sourced by ~/.bashrc and ~/.zshrc

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

if [ -s "$NVM_DIR/nvm.sh" ]; then
    # nvm loads the first time you use it: loading it takes a few hundred
    # milliseconds, and working out the default version takes seconds. The
    # default node goes on PATH directly below instead.
    nvm() {
        unset -f nvm
        . "$NVM_DIR/nvm.sh" --no-use
        [ -n "${BASH_VERSION:-}" ] && [ -r "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
        nvm "$@"
    }

    # Default node: the alias's exact version (v22.11.0), the newest of its
    # major version (22), or else the newest installed (node, lts/*, ...)
    _wsl2dev_default=$(cat "$NVM_DIR/alias/default" 2>/dev/null)
    case $_wsl2dev_default in
        v[0-9]*.*.*) _wsl2dev_match=$_wsl2dev_default ;;
        v[0-9]*|[0-9]*) _wsl2dev_match="v${_wsl2dev_default#v}.*" ;;
        *)           _wsl2dev_match='v*' ;;
    esac
    _wsl2dev_bin=$(find "$NVM_DIR/versions/node" -mindepth 1 -maxdepth 1 -name "$_wsl2dev_match" 2>/dev/null | sort -V | tail -n 1)
    if [ -n "$_wsl2dev_bin" ] && [ -x "$_wsl2dev_bin/bin/node" ]; then
        case ":$PATH:" in
            *":$_wsl2dev_bin/bin:"*) ;;
            *) PATH="$_wsl2dev_bin/bin:$PATH" ;;
        esac
    fi
    unset _wsl2dev_default _wsl2dev_match _wsl2dev_bin
fi

. "${XDG_CONFIG_HOME:-$HOME/.config}/wsl2-dev/node-nvm/direnv-hook.sh"
