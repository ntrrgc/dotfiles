setlocal linebreak sw=4 autoindent

noremap <buffer> k gk
noremap <buffer> j gj

setlocal iskeyword+=127-255

function! s:UpdateHeaderLine()
  let header_line = getline(line('.') + 1)
  if header_line =~# '^[\-=]\+$'
    let line_char = matchstr(header_line, '^[\-=]')
    call setline(substitute(getline('.'), '.', line_char, 'g'))
  endif
endfunction

augroup UpdateHeader
  au!

  autocmd <buffer> CursorMoved,CursorMovedI * call s:UpdateHeaderLine()
augroup END
