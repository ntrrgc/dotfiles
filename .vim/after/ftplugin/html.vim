setlocal sw=2 ts=2

imap <buffer> <Tab> <Esc>:call emmet#moveNextPrev(0)<CR>
imap <buffer> <S-Tab> <Esc>:call emmet#moveNextPrev(1)<CR>

let g:user_emmet_expandabbr_key = '<C-Space>'
let g:user_emmet_leader_key = '<C-Z>'
