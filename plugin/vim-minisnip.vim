let g:minisnip_dir = get(g:, 'minisnip_dir', $HOME . '/.vim/minisnip')
let g:minisnip_trigger = get(g:, 'minisnip_trigger', '<Tab>')
let g:minisnip_startdelim = get(g:, 'minisnip_startdelim', '{{+')
let g:minisnip_enddelim = get(g:, 'minisnip_enddelim', '+}}')
let g:minisnip_evalmarker = get(g:, 'minisnip_evalmarker', '~')
let g:minisnip_backrefmarker = get(g:, 'minisnip_backrefmarker', '\\~')

let s:delimpat = '\V' . g:minisnip_startdelim . '\.\{-}' . g:minisnip_enddelim

let s:placeholder_texts = []
let s:placeholder_text = ''

function! Minisnip()
    normal! ms"syiw`s

    let l:snippetfile = g:minisnip_dir . '/' . @s
    let l:ft_snippetfile = g:minisnip_dir . '/_' . &filetype . '_' . @s

    if filereadable(l:snippetfile)
        let s:placeholder_texts = []
        normal! "_diw
        execute 'read ' . escape(l:snippetfile, '#%')
        normal! kJ
        call SelectPlaceholder()
    elseif filereadable(l:ft_snippetfile)
        let s:placeholder_texts = []
        normal! "_diw
        execute 'read ' . escape(l:ft_snippetfile, '#%')
        normal! kJ
        call SelectPlaceholder()
    else
        normal! ms"syv`<`s
        let s:placeholder_text = @s
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
    keeppatterns execute 'normal! /' . s:delimpat . "/e\<cr>"
    keeppatterns execute 'normal! gn"sy'

    call add(s:placeholder_texts, s:placeholder_text)

    let @s=substitute(@s, '\V' . g:minisnip_startdelim, '', '')
    let @s=substitute(@s, '\V' . g:minisnip_enddelim, '', '')

    if @s =~ '\V\^' . g:minisnip_evalmarker
        let @s=substitute(@s, '\V\^' . g:minisnip_evalmarker, '', '')
        let @s=substitute(@s, '\V' . g:minisnip_backrefmarker . '\(\d\)',
            \"\\=\"'\" . get(
            \    s:placeholder_texts,
            \    len(s:placeholder_texts) - str2nr(submatch(1)), ''
            \) . \"'\"", 'g')
        let @s=eval(@s)
    endif

    if empty(@s)
        normal! gvd
        call feedkeys('a', 'n')
    else
        execute "normal! gv\"spgv\<C-g>"
    endif
endfunction

execute 'inoremap ' . g:minisnip_trigger . ' x<bs><esc>:silent! call Minisnip()<cr>'
execute 'snoremap ' . g:minisnip_trigger . ' <esc>:silent! call Minisnip()<cr>'
