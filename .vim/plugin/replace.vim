function! QuickReplace()
  let old_word = expand("<cword>")
  if old_word == ""
    echoerr "No word selected."
    return
  endif

  let new_word = input(old_word . " -> ", "")

  if new_word != ""
    let line = line(".")
    let col = col(".")

    execute '%s/\V\<'.old_word.'\>/'.new_word.'/gc'

    call setpos(".", [0, line, col, 0])
  endif
endfunction

nnoremap <M-r> :call QuickReplace()<CR>
