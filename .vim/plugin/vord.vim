function! MoveVord()
  let word = expand("<cword>")
  if word =~? '_'
    normal! f_
  elseif word !~# '^[[:upper:]]\+$\|^[[:lower:]]\+$\|^[[:digit:]]\+$'
    if getline(".")[col(".")] =~# '[[:digit:]]'
      execute "normal! /[^[:digit:]]\<CR>"
    else
      execute "normal! /[[:upper:]]\\|[[:digit:]]\<CR>"
    endif
  else
    normal! w
  endif
endfunction

onoremap <silent> v :<C-u>call MoveVord()<CR>
nnoremap <silent> _ :<C-u>call MoveVord()<CR>
