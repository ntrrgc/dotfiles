setlocal linebreak sw=4 autoindent

noremap <buffer> k gk
noremap <buffer> j gj

setlocal iskeyword+=127-255

" Thanks to dhruvasagar https://gist.github.com/dhruvasagar/9131986 
function! s:UpdateHeaderLine()
  let header_line = getline(line('.') + 1)
  if header_line =~# '^[\-=]\+$'
    let line_char = matchstr(header_line, '^[\-=]')
    let line_before = getline(line('.') + 1)
    let line_after = substitute(getline(line('.')), '.', line_char, 'g')
    if line_after != line_before
      call setline(line('.') + 1, line_after)
    endif
  endif
endfunction

augroup UpdateHeader
  au!

  autocmd CursorMoved,CursorMovedI <buffer> call s:UpdateHeaderLine()
augroup END
