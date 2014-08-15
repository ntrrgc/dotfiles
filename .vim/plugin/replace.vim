" http://stackoverflow.com/a/6271254/1777162
function! GetVisualSelection()
  " Why is this not a built-in Vim script function?!
  let [lnum1, col1] = getpos("'<")[1:2]
  let [lnum2, col2] = getpos("'>")[1:2]
  let lines = getline(lnum1, lnum2)
  let lines[-1] = lines[-1][: col2 - (&selection == 'inclusive' ? 1 : 2)]
  let lines[0] = lines[0][col1 - 1:]
  return join(lines, "\n")
endfunction

function! QuickReplace(old_word)
  let old_word = a:old_word
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

nnoremap <M-r> :call QuickReplace(expand("<cword>"))<CR>
vnoremap <M-r> :call QuickReplace(GetVisualSelection())<CR>
