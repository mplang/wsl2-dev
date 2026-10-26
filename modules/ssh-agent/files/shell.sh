# wsl2-dev:ssh-agent -- sourced by ~/.bashrc and ~/.zshrc
#
# One ssh-agent for the whole WSL session. keychain starts it with the first
# shell, asks for each key's passphrase once, and points every later shell
# at the same agent.

# Your SSH keys: every ~/.ssh/id_* that has a matching .pub
_wsl2dev_ssh_keys() {
    find "$HOME/.ssh" -maxdepth 1 -name 'id_*.pub' 2>/dev/null | sort |
        while read -r pub; do
            [ -f "${pub%.pub}" ] && basename "${pub%.pub}"
        done
}

if command -v keychain >/dev/null 2>&1; then
    eval "$(keychain --eval --quiet $(_wsl2dev_ssh_keys))"
fi
unset -f _wsl2dev_ssh_keys
