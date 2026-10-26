" wsl2-dev:theme -- loaded by the vim module at the end of its config.
"
" Applies the current theme's colorscheme, background and airline theme, and
" checks again whenever vim regains focus, so `theme NAME` also recolors
" running vims.

let s:conf = (empty($XDG_CONFIG_HOME) ? expand('~/.config') : $XDG_CONFIG_HOME) . '/wsl2-dev/theme'
let s:state = (empty($XDG_STATE_HOME) ? expand('~/.local/state') : $XDG_STATE_HOME) . '/wsl2-dev/theme/current'

function! s:ThemeSettings() abort
    let l:id = filereadable(s:state) ? trim(get(readfile(s:state, '', 1), 0, '')) : ''
    let l:id = empty(l:id) ? 'gruvbox' : l:id
    let l:theme = {'id': l:id}
    for l:dir in ['my-themes', 'themes']
        let l:file = s:conf . '/' . l:dir . '/' . l:id . '.theme'
        if filereadable(l:file)
            for l:line in readfile(l:file)
                let l:m = matchlist(l:line, '^\(VIM_COLORSCHEME\|VIM_BACKGROUND\|AIRLINE_THEME\)=''\([^'']*\)''')
                if !empty(l:m)
                    let l:theme[l:m[1]] = l:m[2]
                endif
            endfor
            break
        endif
    endfor
    return l:theme
endfunction

function! s:ApplyTheme() abort
    let l:theme = s:ThemeSettings()
    if l:theme.id ==# get(s:, 'theme_id', '')
        return
    endif
    let s:theme_id = l:theme.id
    let &background = get(l:theme, 'VIM_BACKGROUND', 'dark')
    execute 'silent! colorscheme' get(l:theme, 'VIM_COLORSCHEME', 'default')
    let g:airline_theme = get(l:theme, 'AIRLINE_THEME', 'dark')
    if exists(':AirlineTheme')
        execute 'AirlineTheme' g:airline_theme
    endif
endfunction

augroup wsl2dev_theme
    autocmd!
    autocmd FocusGained * ++nested call s:ApplyTheme()
augroup END
call s:ApplyTheme()
