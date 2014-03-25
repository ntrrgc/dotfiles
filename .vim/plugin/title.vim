" Thanks to dhruvasagar https://gist.github.com/dhruvasagar/9131986 
function! UpdateHeaderLine()
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

function! MakeTitle()
  let line_char = getchar()
  " Cancel with Esc key
  if line_char == 27
    return 1
  endif

  let line = substitute(getline(line('.')), '.', nr2char(line_char), 'g')
  call append(line('.'), line)
  call append(line('.') + 1, "")
  call append(line('.') + 2, "")
  call setpos('.', [0, line('.') + 3, 1, 0])
endfunction

function! SaveAndMake()
  write
  silent !make html
  silent !f5chrome
endfunction

function! ActivateAutomaticTitle()
  augroup UpdateHeader
    au!

    autocmd CursorMoved,CursorMovedI <buffer> call UpdateHeaderLine()
  augroup END

  noremap <buffer> <silent> tt :call MakeTitle()<CR>
  noremap <buffer> <C-s> :call SaveAndMake()<CR>
endfunction
