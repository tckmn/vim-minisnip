" set default global variable values if unspecified by user
let g:minisnip_dir = fnamemodify(get(g:, 'minisnip_dir', '~/.vim/minisnip'), ':p')
let g:minisnip_trigger = get(g:, 'minisnip_trigger', '<Tab>')
let g:minisnip_startdelim = get(g:, 'minisnip_startdelim', '{{+')
let g:minisnip_enddelim = get(g:, 'minisnip_enddelim', '+}}')
let g:minisnip_evalmarker = get(g:, 'minisnip_evalmarker', '~')
let g:minisnip_backrefmarker = get(g:, 'minisnip_backrefmarker', '\\~')

" this is the pattern used to find placeholders
let g:minisnip_delimpat = '\V' . g:minisnip_startdelim . '\.\{-}' . g:minisnip_enddelim

" plug mappings
" the eval/escape charade is to convert ex. <Tab> into a literal tab, first
" making it \<Tab> and then eval'ing that surrounded by double quotes
inoremap <script> <expr> <Plug>Minisnip minisnip#ShouldTrigger() ?
            \"x\<bs>\<esc>:call \minisnip#Minisnip()\<cr>" :
            \eval('"' . escape(g:minisnip_trigger, '\"<') . '"')
snoremap <script> <expr> <Plug>Minisnip minisnip#ShouldTrigger() ?
            \"\<esc>:call \minisnip#Minisnip()\<cr>" :
            \eval('"' . escape(g:minisnip_trigger, '\"<') . '"')

" add the default mappings if the user hasn't defined any
if !hasmapto('<Plug>Minisnip')
    execute 'imap <unique> ' . g:minisnip_trigger . ' <Plug>Minisnip'
    execute 'smap <unique> ' . g:minisnip_trigger . ' <Plug>Minisnip'
endif
