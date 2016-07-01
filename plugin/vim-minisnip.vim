let g:minisnip_dir = get(g:, "minisnip_dir", $HOME . "/.vim/minisnip")
let g:minisnip_trigger = get(g:, "minisnip_trigger", "<Tab>")

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
            execute "normal! gi" .
                \eval('"' . escape(g:minisnip_trigger, '\"<') . '"')
            call feedkeys("a", "n")
        endtry
    endif
endfunction

execute "inoremap " . g:minisnip_trigger . " x<bs><esc>:call ExpandSnippet()<cr>"
