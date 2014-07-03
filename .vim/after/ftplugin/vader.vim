function! MapSave()
  noremap <buffer> <C-s> :call VaderSave()<CR>
endfunction

function! MapQuit()
  noremap <buffer> <C-s> :call VaderQuit()<CR>
endfunction

function! UnmapQuit()
  unmap <buffer> <C-s>
endfunction

function! VaderSave()
  write
  Vader
  call MapQuit()
endfunction

function! VaderQuit()
  tabclose
endfunction

call MapSave()
