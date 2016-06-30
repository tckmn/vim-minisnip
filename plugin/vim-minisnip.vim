let g:minisnip_dir = get(g:, "minisnip_dir", $HOME . "/.vim/minisnip")

function! ExpandSnippet()
    normal! ms"syiw`s
    let l:snippetfile = g:minisnip_dir . "/" . @s
    if filereadable(l:snippetfile)
        normal! "_diw
        execute "read " . l:snippetfile
        keeppatterns execute "normal! kJ/{{{}}}\<cr>gn\<C-g>"
    else
        try
            keeppatterns execute "normal! /{{{}}}\<cr>"
            execute "normal! gn\<C-g>"
        catch
            execute "normal! gi\<tab>"
            call feedkeys("a", "n")
        endtry
    endif
endfunction

inoremap <tab> x<bs><esc>:call ExpandSnippet()<cr>
