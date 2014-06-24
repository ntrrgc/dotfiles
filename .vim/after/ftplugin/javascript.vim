setlocal sw=2 ts=2

" New lines with semicolon
noremap <buffer> <S-CR> o;<Esc>i
inoremap <buffer> <S-CR> <Esc>o;<Esc>i
inoremap <buffer> <C-CR> <Esc>o

" Expand a JSON object (probably unreliable)
noremap <leader>e ^a<CR><C-t><Esc>f}i<CR><Esc>>>k^
