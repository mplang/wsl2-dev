" wsl2-dev:vim-coc -- loaded by the vim module at the end of its config.
" Updated by modules/vim-coc/install.sh; edits here are lost. Change things
" in ~/.vimrc instead, below the wsl2-dev:vim block.

" ============================================================
" COC: completion, go-to-definition, rename, ... via language servers
" ============================================================

" Language servers installed on first start; add more in ~/.vimrc with
"   let g:coc_global_extensions += ['coc-go']
let g:coc_global_extensions = get(g:, 'coc_global_extensions', []) + [
            \ 'coc-json', 'coc-tsserver', 'coc-pyright', 'coc-sh', 'coc-html',
            \ 'coc-markdownlint', 'coc-eslint', 'coc-prettier', 'coc-snippets']

" node: from PATH, or the newest one nvm installed (nvm may not be loaded
" when vim starts)
if !executable('node') && !exists('g:coc_node_path')
    let s:nvm_nodes = sort(glob(expand('~/.nvm/versions/node/*/bin/node'), 0, 1), 'N')
    if !empty(s:nvm_nodes)
        let g:coc_node_path = s:nvm_nodes[-1]
    endif
endif

function! s:CheckBackspace() abort
    let l:col = col('.') - 1
    return !l:col || getline('.')[l:col - 1] =~# '\s'
endfunction

" Tab / Shift-Tab: move through completions; Enter: accept; Ctrl-Space: complete now
inoremap <silent><expr> <Tab>
            \ coc#pum#visible() ? coc#pum#next(1) :
            \ <SID>CheckBackspace() ? "\<Tab>" :
            \ coc#refresh()
inoremap <expr> <S-Tab> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
            \ : "\<C-g>u\<CR>\<C-r>=coc#on_enter()\<CR>"
inoremap <silent><expr> <C-@> coc#refresh()

" Go to: definition, type, implementation, references; [g ]g: problems
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" K: documentation for the word under the cursor
nnoremap <silent> K :call <SID>ShowDocumentation()<CR>
function! s:ShowDocumentation() abort
    if CocAction('hasProvider', 'hover')
        call CocActionAsync('doHover')
    else
        call feedkeys('K', 'in')
    endif
endfunction

augroup wsl2dev_coc
    autocmd!
    " Highlight other uses of the symbol under the cursor
    autocmd CursorHold * silent call CocActionAsync('highlight')
    autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup END

" Rename, format, code actions, quick fix
nmap <leader>rn <Plug>(coc-rename)
xmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)
xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>ac <Plug>(coc-codeaction-cursor)
nmap <leader>qf <Plug>(coc-fix-current)
nmap <silent> <leader>re <Plug>(coc-codeaction-refactor)
nmap <leader>cl <Plug>(coc-codelens-action)

" Text objects: if/af (function), ic/ac (class)
xmap if <Plug>(coc-funcobj-i)
omap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap af <Plug>(coc-funcobj-a)
xmap ic <Plug>(coc-classobj-i)
omap ic <Plug>(coc-classobj-i)
xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)

" Ctrl-F / Ctrl-B scroll popups (and the page, as usual, when there are none)
nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
nnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
inoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? "\<C-r>=coc#float#scroll(1)\<CR>" : "\<Right>"
inoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? "\<C-r>=coc#float#scroll(0)\<CR>" : "\<Left>"

" :Format the file, :OR organize imports
command! -nargs=0 Format call CocActionAsync('format')
command! -nargs=0 OR call CocActionAsync('runCommand', 'editor.action.organizeImport')

" Space + a: problems, o: outline, s: symbols, c: commands, e: extensions
nnoremap <silent><nowait> <Space>a :<C-u>CocList diagnostics<CR>
nnoremap <silent><nowait> <Space>o :<C-u>CocList outline<CR>
nnoremap <silent><nowait> <Space>s :<C-u>CocList -I symbols<CR>
nnoremap <silent><nowait> <Space>c :<C-u>CocList commands<CR>
nnoremap <silent><nowait> <Space>e :<C-u>CocList extensions<CR>
nnoremap <silent><nowait> <Space>p :<C-u>CocListResume<CR>

let g:airline#extensions#coc#enabled = 1

" ============================================================
" ALE: fixers on demand; shows CoC's diagnostics (coc-settings.json)
" ============================================================

let g:ale_disable_lsp = 1        " CoC does the language servers
let g:ale_fixers = get(g:, 'ale_fixers', {'*': ['remove_trailing_lines', 'trim_whitespace']})
let g:ale_sign_error = 'x'
let g:ale_sign_warning = '!'
nmap <leader>d <Plug>(ale_fix)
let g:airline#extensions#ale#enabled = 1
