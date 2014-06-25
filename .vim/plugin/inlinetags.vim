let g:inlinetags_path = expand("<sfile>:h") . "/../"

python << EOF
import sys
import vim
sys.path.append(vim.eval("g:inlinetags_path"))
import inlinetags_vim
EOF

autocmd FileType html nnoremap <buffer> <silent> % 
        \<Esc>:python inlinetags_vim.jump_to_pairing("n")<CR>
autocmd FileType html vnoremap <buffer> <silent> % 
        \<Esc>:python inlinetags_vim.jump_to_pairing("v")<CR>
