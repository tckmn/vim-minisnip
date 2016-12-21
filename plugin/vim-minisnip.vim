" set default global variable values if unspecified by user
let g:minisnip_dir = get(g:, 'minisnip_dir', $HOME . '/.vim/minisnip')
let g:minisnip_trigger = get(g:, 'minisnip_trigger', '<Tab>')
let g:minisnip_startdelim = get(g:, 'minisnip_startdelim', '{{+')
let g:minisnip_enddelim = get(g:, 'minisnip_enddelim', '+}}')
let g:minisnip_evalmarker = get(g:, 'minisnip_evalmarker', '~')
let g:minisnip_backrefmarker = get(g:, 'minisnip_backrefmarker', '\\~')

" this is the pattern used to find placeholders
let s:delimpat = '\V' . g:minisnip_startdelim . '\.\{-}' . g:minisnip_enddelim

function! <SID>ShouldTrigger()
    silent! unlet! s:snippetfile
    let l:cword = matchstr(getline('.'), '\v\w+%' . col('.') . 'c')

    " look for a snippet by that name
    let l:snippetfile = g:minisnip_dir . '/' . l:cword
    let l:ft_snippetfile = g:minisnip_dir . '/_' . &filetype . '_' . l:cword
    if filereadable(l:ft_snippetfile)
        " filetype snippets override general snippets
        let l:snippetfile = l:ft_snippetfile
    endif

    " make sure the snippet exists
    if filereadable(l:snippetfile)
        let s:snippetfile = l:snippetfile
        return 1
    endif

    return search(s:delimpat, 'e')
endfunction

" main function, called on press of Tab (or whatever key Minisnip is bound to)
function! <SID>Minisnip()
    if exists("s:snippetfile")
        " reset placeholder text history (for backrefs)
        let s:placeholder_texts = []
        let s:placeholder_text = ''
        " remove the snippet name
        normal! "_diw
        " insert the snippet
        execute 'read ' . escape(s:snippetfile, '#%')
        " remove the empty line before the snippet
        normal! kJ
        " select the first placeholder
        call s:SelectPlaceholder()
    else
        " save the current placeholder's text so we can backref it
        normal! ms"syv`<`s
        let s:placeholder_text = @s
        " jump to the next placeholder
        call s:SelectPlaceholder()
    endif
endfunction

" this is the function that finds and selects the next placeholder
function! s:SelectPlaceholder()
    " get the contents of the placeholder
    " we use /e here in case the cursor is already on it (which occurs ex.
    "   when a snippet begins with a placeholder)
    " we also use keeppatterns to avoid clobbering the search history /
    "   highlighting all the other placeholders
    keeppatterns execute 'normal! /' . s:delimpat . "/e\<cr>gn\"sy"

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
" the eval/escape charade is to convert ex. <Tab> into a literal tab, first
" making it \<Tab> and then eval'ing that surrounded by double quotes
inoremap <unique> <script> <expr> <Plug>Minisnip <SID>ShouldTrigger() ?
            \"x\<bs>\<esc>:call \<SID>Minisnip()\<cr>" :
            \eval('"' . escape(g:minisnip_trigger, '\"<') . '"')
snoremap <unique> <script> <expr> <Plug>Minisnip <SID>ShouldTrigger() ?
            \"\<esc>:call \<SID>Minisnip()\<cr>" :
            \eval('"' . escape(g:minisnip_trigger, '\"<') . '"')

" add the default mappings if the user hasn't defined any
if !hasmapto('<Plug>Minisnip')
    execute 'imap <unique> ' . g:minisnip_trigger . ' <Plug>Minisnip'
    execute 'smap <unique> ' . g:minisnip_trigger . ' <Plug>Minisnip'
endif
