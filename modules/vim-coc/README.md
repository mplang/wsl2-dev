# vim-coc

IDE-style features in vim through language servers, with
[coc.nvim](https://github.com/neoclide/coc.nvim): completion as you type,
go to definition, find references, rename, documentation popups, code
actions and formatting. [ALE](https://github.com/dense-analysis/ale) adds
fixers (`\d`) and shows CoC's errors and warnings in the sign column.

Needs the [`vim`](../vim/) module, which loads this one's files, and
[node](https://nodejs.org/) (CoC runs on it).

| Key | Does |
|-----|------|
| **Tab** / **Shift-Tab** (insert) | next / previous completion; **Enter** accepts |
| **Ctrl-Space** (insert) | show completions now |
| `gd`, `gy`, `gi`, `gr` | go to definition, type, implementation, references |
| `K` | documentation for the word under the cursor |
| `[g` / `]g` | previous / next problem |
| `\rn` | rename the symbol everywhere |
| `\f` | format the selection; `:Format` formats the file |
| `\a`, `\ac` | code actions for the selection / at the cursor |
| `\qf` | apply the quick fix for the problem on this line |
| `\re` | refactor |
| `\d` | run ALE's fixers (trims trailing whitespace and blank lines) |
| `if`/`af`, `ic`/`ac` | text objects: inside/around a function or class, e.g. `daf` |
| **Ctrl-F** / **Ctrl-B** | scroll a popup |
| **Space** then `a` / `o` / `s` / `c` / `e` | lists: problems, outline, symbols, commands, extensions |
| `:OR` | organize imports |

Language servers ([CoC extensions](https://github.com/neoclide/coc.nvim/wiki/Using-coc-extensions))
installed on first start: JSON, TypeScript/JavaScript, Python (pyright),
shell, HTML, Markdown lint, ESLint, Prettier, and snippets.

## Install

```bash
../vim/install.sh         # first, if you haven't
./install.sh --dry-run    # see what it would do
./install.sh
```

It puts `vim-plugins.vim` and `vim-config.vim` in
`~/.config/wsl2-dev/vim-coc/`, where the vim module picks them up, and
installs coc.nvim and ALE. If no `node` is found (on `PATH` or from
[nvm](../node-nvm/)), it installs Ubuntu's `nodejs` (asking before it uses
`sudo`). It creates `~/.vim/coc-settings.json` if you don't have one.

The first time you open vim, CoC installs the language servers in the
background (a minute or so; `:CocInfo` shows progress).

**Check:** open a Python or TypeScript file, put the cursor on a function
call and press `gd`.

### More languages

Add CoC extensions in `~/.vimrc`, below the `wsl2-dev:vim` block:

```vim
let g:coc_global_extensions = ['coc-go', 'coc-rust-analyzer', 'coc-java']
```

These are added to the defaults and installed the next time vim starts.
`:CocInstall coc-go` also works.

CoC settings (formatters, language server options) go in
`~/.vim/coc-settings.json`, or `:CocConfig`. It's yours: the installer
never changes it. For example, to format Python with black:

```json
{
    "suggest.noselect": true,
    "diagnostic.displayByAle": true,
    "python.formatting.provider": "black"
}
```

## Remove

```bash
./install.sh --uninstall
```

Then `:PlugClean` in vim deletes coc.nvim and ALE. Your
`~/.vim/coc-settings.json` and CoC's extensions (`~/.config/coc`) stay.

## Notes

- **node from nvm**: vim starts before nvm is loaded in some setups, so this
  module points CoC at the newest node in `~/.nvm` when there's none on
  `PATH`.
- **`\r` mappings**: `\rn` and `\re` are CoC's. If your own `~/.vimrc` maps
  `\r` to something, vim waits briefly after `\r` to tell them apart.
