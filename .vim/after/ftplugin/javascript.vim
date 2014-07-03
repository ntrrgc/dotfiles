setlocal sw=2 ts=2

" Expand a JSON object (probably unreliable)
noremap <leader>e ^a<CR><C-t><Esc>f}i<CR><Esc>>>k^
