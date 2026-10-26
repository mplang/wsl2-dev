# wsl2-dev:zsh -- sourced by ~/.zshrc
#
# Sensible zsh defaults that work with or without a framework (oh-my-zsh,
# prezto, ...). Where a framework or another module already set something
# up, it's left alone.

# --- PATH: zsh doesn't read ~/.profile, where Ubuntu adds these ---
typeset -U path
path=(~/.local/bin(N-/) ~/bin(N-/) $path)

# --- History: large, shared between terminals, no duplicates ---
HISTFILE=${HISTFILE:-~/.zsh_history}
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY       # save when each command ran
setopt SHARE_HISTORY          # every terminal sees new commands right away
setopt HIST_IGNORE_ALL_DUPS   # a repeated command replaces its older copy
setopt HIST_IGNORE_SPACE      # a command typed with a leading space isn't saved
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY            # !! and friends expand for review instead of running

# --- Directories ---
setopt AUTO_CD                # type a directory's name to cd into it
setopt AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT   # cd -<Tab> lists recent ones

# --- Completion ---
# Frameworks run compinit themselves; run it only if nothing has
if (( ! ${+_comps} )); then
    autoload -Uz compinit && compinit
fi
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'   # case-insensitive
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# Pick completions with the arrow keys, unless something (e.g. fzf-tab)
# already chose how completion menus work
zstyle -s ':completion:*' menu _wsl2dev_menu || zstyle ':completion:*' menu select
unset _wsl2dev_menu

# --- Keys (as Windows Terminal sends them) ---
# Up/Down: previous/next command starting with what you've typed (unless a
# history-search plugin already took the arrows)
if (( ! ${+functions[history-substring-search-up]} )); then
    autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
    zle -N up-line-or-beginning-search
    zle -N down-line-or-beginning-search
    bindkey '^[[A' up-line-or-beginning-search   '^[OA' up-line-or-beginning-search
    bindkey '^[[B' down-line-or-beginning-search '^[OB' down-line-or-beginning-search
fi
bindkey '^[[1;5D' backward-word '^[[1;5C' forward-word   # Ctrl-Left/Right
bindkey '^[[3;5~' kill-word                              # Ctrl-Delete
bindkey '^[[H' beginning-of-line '^[[F' end-of-line '^[[3~' delete-char

# --- Autosuggestions: a grey suggestion from history; Right arrow accepts ---
if (( ! ${+functions[_zsh_autosuggest_start]} )) &&
   [[ -r /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# --- Prompt: a simple git-aware one, only if nothing set a prompt ---
# (zsh's default is just "host%")
if [[ $PROMPT == '%m%# ' ]]; then
    autoload -Uz vcs_info add-zsh-hook
    add-zsh-hook precmd vcs_info
    zstyle ':vcs_info:git:*' formats ' %F{magenta}%b%f'
    zstyle ':vcs_info:git:*' actionformats ' %F{magenta}%b%f %F{red}%a%f'
    setopt PROMPT_SUBST
    PROMPT='%F{blue}%~%f${vcs_info_msg_0_} %(?.%F{green}.%F{red})%#%f '
fi
