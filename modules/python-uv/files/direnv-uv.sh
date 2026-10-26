# wsl2-dev:python-uv -- loaded by direnv (from ~/.config/direnv/lib/).
#
# `layout uv` in a project's .envrc: installs what uv.lock lists into .venv
# (uv sync --frozen; never changes uv.lock) and activates .venv. Built into
# direnv 2.38+; this copy (from direnv's stdlib, MIT) is for older versions,
# e.g. Ubuntu 26.04's 2.37.

if ! declare -F layout_uv >/dev/null; then
layout_uv() {
  watch_file .python-version pyproject.toml uv.lock

  if ! has uv; then
    log_error "uv: command not found. Install from https://docs.astral.sh/uv/"
    return 1
  fi

  if [[ ! -f pyproject.toml ]]; then
    log_error "uv: no pyproject.toml found. Run \`uv init\` to create a project."
    return 1
  fi

  local venv_path
  venv_path=$(expand_path "${UV_PROJECT_ENVIRONMENT:-.venv}")
  export UV_PROJECT_ENVIRONMENT=$venv_path

  uv sync --frozen "$@" || return

  export VIRTUAL_ENV=$venv_path
  if [[ -d "$venv_path/bin" ]]; then
    PATH_add "$venv_path/bin"
  fi
}
fi
