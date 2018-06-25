let g:inlinetags_path = expand("<sfile>:h") . "/../"

python3 << EOF
import sys
import vim
sys.path.append(vim.eval("g:inlinetags_path"))
import inlinetags_vim
EOF

autocmd FileType html nnoremap <buffer> <silent> % 
        \<Esc>:python3 inlinetags_vim.jump_to_pairing("n")<CR>
autocmd FileType html vnoremap <buffer> <silent> % 
        \<Esc>:python3 inlinetags_vim.jump_to_pairing("v")<CR>

autocmd FileType html nnoremap <buffer> <silent> <C-e> 
        \<Esc>:python3 inlinetags_vim.vim_expand_tag("n")<CR>
