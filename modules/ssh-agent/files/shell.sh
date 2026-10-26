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

# The agent keychain started earlier, if it's still running (fast path:
# keychain itself takes a moment to start)
_wsl2dev_agent=$HOME/.keychain/${HOSTNAME:-${HOST:-$(hostname)}}-sh
[ -r "$_wsl2dev_agent" ] && . "$_wsl2dev_agent" >/dev/null
# ssh-add -l: 0 = keys loaded, 1 = agent without keys, 2 = no agent
if ! ssh-add -l >/dev/null 2>&1 && command -v keychain >/dev/null 2>&1; then
    eval "$(keychain --eval --quiet $(_wsl2dev_ssh_keys))"
fi
unset _wsl2dev_agent
unset -f _wsl2dev_ssh_keys
