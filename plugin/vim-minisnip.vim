let g:minisnip_dir = get(g:, 'minisnip_dir', $HOME . '/.vim/minisnip')
let g:minisnip_trigger = get(g:, 'minisnip_trigger', '<Tab>')
let g:minisnip_startdelim = get(g:, 'minisnip_startdelim', '{{+')
let g:minisnip_enddelim = get(g:, 'minisnip_enddelim', '+}}')
let g:minisnip_evalmarker = get(g:, 'minisnip_evalmarker', '~')

let s:delimpat = '\V' . g:minisnip_startdelim . '\.\{-}' . g:minisnip_enddelim

function! ExpandSnippet()
    normal! ms"syiw`s
    let l:snippetfile = g:minisnip_dir . '/' . @s
    if filereadable(l:snippetfile)
        normal! "_diw
        execute 'read ' . l:snippetfile
        normal! kJ
        call SelectPlaceholder()
    else
        try
            call SelectPlaceholder()
        catch
            execute 'normal! gi' .
                \eval('"' . escape(g:minisnip_trigger, '\"<') . '"')
            call feedkeys('a', 'n')
        endtry
    endif
endfunction

function! SelectPlaceholder()
    keeppatterns execute 'normal! /' . s:delimpat . "\<cr>"
    keeppatterns execute 'normal! gn"sy'

    let @s=substitute(@s, '\V' . g:minisnip_startdelim, '', '')
    let @s=substitute(@s, '\V' . g:minisnip_enddelim, '', '')

    if @s =~ '\V\^' . g:minisnip_evalmarker
        let @s=substitute(@s, '\V\^' . g:minisnip_evalmarker, '', '')
        let @s=eval(@s)
    endif

    if empty(@s)
        normal! gvd
        call feedkeys('a', 'n')
    else
        execute "normal! gv\"spgv\<C-g>"
    endif
endfunction

execute 'inoremap ' . g:minisnip_trigger . ' x<bs><esc>:call ExpandSnippet()<cr>'
