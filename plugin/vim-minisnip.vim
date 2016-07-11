" set default global variable values if unspecified by user
let g:minisnip_dir = get(g:, 'minisnip_dir', $HOME . '/.vim/minisnip')
let g:minisnip_trigger = get(g:, 'minisnip_trigger', '<Tab>')
let g:minisnip_startdelim = get(g:, 'minisnip_startdelim', '{{+')
let g:minisnip_enddelim = get(g:, 'minisnip_enddelim', '+}}')
let g:minisnip_evalmarker = get(g:, 'minisnip_evalmarker', '~')
let g:minisnip_backrefmarker = get(g:, 'minisnip_backrefmarker', '\\~')

" this is the pattern used to find placeholders
let s:delimpat = '\V' . g:minisnip_startdelim . '\.\{-}' . g:minisnip_enddelim

" main function, called on press of Tab (or whatever key Minisnip is bound to)
function! <SID>Minisnip()
    " yank whatever word we're on (without moving the cursor)
    normal! ms"syiw`s

    " look for a snippet by that name
    let l:snippetfile = g:minisnip_dir . '/' . @s
    let l:ft_snippetfile = g:minisnip_dir . '/_' . &filetype . '_' . @s
    if filereadable(l:ft_snippetfile)
        " filetype snippets override general snippets
        let l:snippetfile = l:ft_snippetfile
    endif

    " make sure a.) we're at the end of the word, and b.) the snippet exists
    if (getline('.') !~# ('\v%' . (col('.') + 1) . 'c\w')) &&
            \filereadable(l:snippetfile)
        " reset placeholder text history (for backrefs)
        let s:placeholder_texts = []
        let s:placeholder_text = ''
        " remove the snippet name
        normal! "_diw
        " insert the snippet
        execute 'read ' . escape(l:snippetfile, '#%')
        " remove the empty line before the snippet
        normal! kJ
        " select the first placeholder
        call s:SelectPlaceholder()
    else
        " let's check if we're jumping to the next placeholder instead
        " first, save the current placeholder's text so we can backref it
        normal! ms"syv`<`s
        let s:placeholder_text = @s
        " see if there's another placeholder somewhere in the file
        try
            call s:SelectPlaceholder()
        catch
            " nothing. this is just a normal Tab (or other key) press
            " the eval/escape charade is to convert ex. <Tab> into a literal
            "   tab, first making it \<Tab> and then eval'ing that surrounded
            "   by double quotes
            execute 'normal! gi' .
                \eval('"' . escape(g:minisnip_trigger, '\"<') . '"')
            " get back in insert mode after we return
            call feedkeys('a', 'n')
        endtry
    endif
endfunction

" this is the function that finds and selects the next placeholder
function! s:SelectPlaceholder()
    " first, check if it's there
    " we use /e here in case the cursor is already on it (which occurs ex.
    "   when a snippet begins with a placeholder)
    " we also use keeppatterns to avoid clobbering the search history /
    "   highlighting all the other placeholders
    keeppatterns execute 'normal! /' . s:delimpat . "/e\<cr>"
    " if it's not, this function will error out right here (so the following
    "   is never executed)
    " get the contents of the placeholder
    keeppatterns execute 'normal! gn"sy'

    " save the contents of the previous placeholder (for backrefs)
    call add(s:placeholder_texts, s:placeholder_text)

    " remove the start and end delimiters
    let @s=substitute(@s, '\V' . g:minisnip_startdelim, '', '')
    let @s=substitute(@s, '\V' . g:minisnip_enddelim, '', '')

    " is this placeholder marked as 'evaluate'?
    if @s =~ '\V\^' . g:minisnip_evalmarker
        " remove the marker
        let @s=substitute(@s, '\V\^' . g:minisnip_evalmarker, '', '')
        " substitute in any backrefs
        let @s=substitute(@s, '\V' . g:minisnip_backrefmarker . '\(\d\)',
            \"\\=\"'\" . substitute(get(
            \    s:placeholder_texts,
            \    len(s:placeholder_texts) - str2nr(submatch(1)), ''
            \), \"'\", \"''\", 'g') . \"'\"", 'g')
        " evaluate what's left
        let @s=eval(@s)
    endif

    if empty(@s)
        " the placeholder was empty, so just enter insert mode directly
        normal! gvd
        call feedkeys('a', 'n')
    else
        " paste the placeholder's default value in and enter select mode on it
        execute "normal! gv\"spgv\<C-g>"
    endif
endfunction

" plug mappings
inoremap <unique> <script> <Plug>Minisnip x<bs><esc>:silent! call <SID>Minisnip()<cr>
snoremap <unique> <script> <Plug>Minisnip <esc>:silent! call <SID>Minisnip()<cr>

" add the default mappings if the user hasn't defined any
if !hasmapto('<Plug>Minisnip')
    execute 'imap <unique> ' . g:minisnip_trigger . ' <Plug>Minisnip'
    execute 'smap <unique> ' . g:minisnip_trigger . ' <Plug>Minisnip'
endif
