augroup webkitexpectations
    " Shorten Bugzilla links with F8
    autocmd BufReadPost TestExpectations :noremap <F8> df=iwebkit.org/b/<Esc>B
augroup END
