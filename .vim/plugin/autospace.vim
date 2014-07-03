let g:operators = "=+-/*<>|&%^:"
let g:separators = ","
if !exists("g:TypeOnBackSpace")
  let g:TypeOnBackSpace = "\<BS>"
endif

function! EscapeKey(key)
  if a:key == '|'
    return '\|'
  else
    return a:key
  endif
endfunction

function! EnableAutoSpaces()
  for op in split(g:operators, '\zs')
    if op == "-"
      execute 'inoremap <buffer> <silent> ' . op . ' <Esc>:call InsertMinus()<CR>'
    else
      execute 'inoremap <buffer> <silent> ' . EscapeKey(op) .
            \ ' <Esc>:call InsertOperator("' . EscapeKey(op) .'")<CR>'
    endif
  endfor

  for sep in split(g:separators, '\zs')
    execute 'inoremap <buffer> <silent> ' . sep . ' <Esc>:call InsertSeparator("' . sep .'")<CR>'
  endfor

  inoremap <buffer> <silent> <BS> <C-R>=DeleteCharacter()<CR>
endfunction

function! InsertSeparator(sep)
  if !InString()
    " Append an space after the separator if there is none already
    let spaceAfter = matchstr(getline("."), '\%' . (col(".") + 1) . 'c.') 
          \ != " " ? " " : ""

    call feedkeys("a" . a:sep . spaceAfter, "n")
    if spaceAfter == ""
      " There was already an space, advance to it
      call feedkeys("\<Esc>la", "n")
    endif
  else
    call feedkeys("a" . a:sep, "n")
  endif
endfunction

function! PreviousChars(str, pos)
  " Return the two previous non-space characters of `str` at position `pos` (0
  " indexed)
  " If not enough characters, pads with empty strings to the left
  let chars = []
  let pos = a:pos

  for i in [1, 2]
    let pos = match(a:str, '\v\S\s*%'.(pos+1).'c')
    let chars = insert(chars, a:str[pos])
  endfor

  return chars
endfunction

python << EOF
import vim

class ExhaustedDocument(Exception):
  pass

def prev_char(line, col):
  if col > 0:
      return line, col - 1
  elif line > 0:
      new_line = line - 1
      new_col = len(vim.current.buffer[new_line]) - 1
      return new_line, new_col
  else:
      raise ExhaustedDocument

def enclosed(line, col, opening, closing):
  # (line, col) are 0-indexed
  try:
      paren_level = 0
      while True:
          try:
              char = vim.current.buffer[line][col]
          except IndexError:
              # Happens if we start at an empty line.
              line, col = prev_char(line, col)
              continue

          if char == opening and paren_level == 0:
              return True
          elif char == closing:
              paren_level -= 1
          elif char == opening:
              paren_level += 1

          line, col = prev_char(line, col)
  except ExhaustedDocument:
      return False

def star_is_args_interpolation(line, col):
  # (line, col) are 0-indexed
  try:
      while True:
          char = vim.current.buffer[line][col]

          if char in ("(", ","):
              return True
          elif not char.isspace() and char != "*":
              return False

          line, col = prev_char(line, col)
  except ExhaustedDocument:
      return False
EOF

function! InPythonFunctionCall(line, col)
  " var = fun(**kwargs)
  " getMyObject().prop = 3 * 5
  " thing = myfun(arg1, arg2, arg3,
  "               arg4="Hello")
  " We consider we're in the context of a function call if searching backwards
  " we find a '(' without pair or which pair is after the cursor.

  python << EOF
if enclosed(int(vim.eval("a:line")) - 1,
            int(vim.eval("a:col")) - 1,
            "(", ")"):
    vim.command("return 1")
else:
    vim.command("return 0")
EOF
endfunction

function! InBraces(line, col)
  python << EOF
if enclosed(int(vim.eval("a:line")) - 1,
            int(vim.eval("a:col")) - 1,
            "{", "}"):
    vim.command("return 1")
else:
    vim.command("return 0")
EOF
endfunction

function! InBrackets(line, col)
  python << EOF
if enclosed(int(vim.eval("a:line")) - 1,
            int(vim.eval("a:col")) - 1,
            "[", "]"):
    vim.command("return 1")
else:
    vim.command("return 0")
EOF
endfunction

function! StarIsArgsInterpolation(line, col)
  " A star is argument interpolation if at the left it has '(' or ','

  python << EOF
if star_is_args_interpolation(int(vim.eval("a:line")) - 1,
                              int(vim.eval("a:col")) - 1):
    vim.command("return 1")
else:
    vim.command("return 0")
EOF
endfunction

function! InsertOperator(op)
  if !InString()
    let compositeOperators = [
          \ '===', '!==', '==', '!=', '<>', '&&', '||', '<=', '>=', '=~',
          \ '-=', '+=', '*=', '/=', '%=', '&=', '|=', '^=', '!~', 
          \ '--', '++', '<<', '>>', '//'
          \ ]

    if &ft == "python"
      let compositeOperators = add(compositeOperators, "**")

      if a:op == "="
        let prevOps = PreviousChars(getline("."), col("."))
        if prevOps[1] != "=" && InPythonFunctionCall(line("."), col("."))
          " No spaces
          call feedkeys("a" . a:op, "n")
          return
        endif
      elseif a:op == "*"
        if StarIsArgsInterpolation(line("."), col("."))
          " No spaces
          call feedkeys("a" . a:op, "n")
          return
        endif
      endif
    endif

    let prevOps = PreviousChars(getline("."), col("."))
    if !empty(prevOps)
      let potentialCompOp = prevOps[0] . prevOps[1] . a:op

      for compOp in compositeOperators
        " if potentialCompOp.endswith(compOn)
        if match(potentialCompOp, '\V' . escape(compOp, '\/') . '\$') != -1
          call HandleCompositeOperator(compOp)
          return
        endif
      endfor
    endif

    " Insert an space before if the cursor is not already over one
    let spaceBefore = matchstr(getline("."), '\%' . col(".") . 'c.') 
          \ != " " ? " " : ""
    " Append an space after the operator if there is none already
    let spaceAfter = matchstr(getline("."), '\%' . (col(".") + 1) . 'c.') 
          \ != " " ? " " : ""

    " Dictionary keys
    if a:op == ":"
      let spaceBefore = ""
      if InBraces(line("."), col("."))
        let spaceAfter = " "
      else
        let spaceAfter = ""
      endif
    endif

    " C unary operators & and *
    let unary = 0
    if a:op == "&" || a:op == "*"
      " It's unary if it's after an operator or (
      if match(prevOps[1], '\v[=+-/*<>|&%\^(~]') != -1
        " Do not envelop unary operators with spaces
        let spaceBefore = (prevOps == "=" ? " " : "")
        let spaceAfter = ""
        let unary = 1
      endif
    endif

    call feedkeys("a" . spaceBefore . a:op . spaceAfter, "n")
    if spaceAfter == "" && !unary && a:op != ":"
      " There was already an space, advance to it
      call feedkeys("\<Esc>la", "n")
    endif
  else
    call feedkeys("a" . a:op, "n")
  endif
endfunction

function! InsertMinus()
  " Check if the previous non-empty character was an operator
  let previous = matchstr(getline("."), '\v([^ ]) *%'.col(".").'c')
  if stridx(g:operators, previous) != -1 && previous != "-"
    " It was an operator, this will be a negative number
    " Do not write space
    call feedkeys("a-", "n")
  else
    " It was another thing, this will be an operator
    call InsertOperator("-")
  endif
endfunction

function! InString()
  " col + 1 because <Esc> goes one character back
  let tokens = synstack(line("."), col(".") + 1)
  if !empty(tokens)
    let tokenName = synIDattr(tokens[-1], "name")
    return stridx(tolower(tokenName), "string") != -1
  else
    return 0
  endif
endfunction

function! HandleCompositeOperator(op)
  " count of operators to replace (length of the desired operator minus the
  " character yet to write)
  let numOps = strlen(a:op) - 1
  let op = a:op

  " Abbreviation: in Python convert &&, || to and, or
  if &ft == "python"
    let abbr = {"&&": "and", "||": "or"}
    if has_key(abbr, op)
      let op = abbr[op]
    endif
  endif

  if op == "--" || op == "++"
    " Do not put spaces to pre/post increment/decrement operators
    let opWithSpaces = op
  elseif op == "//" && &ft != "python"
    let opWithSpaces = op." "
  else
    let opWithSpaces = " ".op." "
  endif

  " Find the old operator string and replace it with the new operator,
  " surrounded with spaces
  let colBefore = col(".")
  let lenBefore = strlen(getline("."))
  execute 's/\v(\s*\S){'.numOps.'}\s*%'.(col(".")+1).'c/'.escape(opWithSpaces, '&/\').'/'
  let lenAfter = strlen(getline("."))

  " Position the cursor after the new operator
  call setpos(".", [0, line("."), colBefore + (lenAfter - lenBefore), 0])
  call feedkeys("a", "n")
endfunction

function! CharByPos(str, pos)
  " Return the `pos` character in str, starting to count from 0
  return matchstr(a:str, '\%'.(a:pos + 1).'c.')
endfunction

function! DeleteCharacter()
  " The cursor is now over the character to be deleted

  let line = getline(".")
  let pos = col(".") - 2
  let firstChar = match(line, '\S')

  let keys = ""

  " Delete spaces (except indentation)
  if firstChar > -1
    while CharByPos(line, pos) == " " && pos > firstChar
      let keys .= "\<BS>"
      let pos -= 1
    endwhile
  endif

  let keys .= g:TypeOnBackSpace
  let pos -= 1

  " If an operator was deleted, delete more spaces (except indentation)
  if firstChar > -1 && match(CharByPos(line, pos + 1), '\v[=+-/*<>|&%\^~]') != -1 
    while CharByPos(line, pos) == " " && pos > firstChar
      let keys .= "\<BS>"
      let pos -= 1
    endwhile
  endif
  return keys
endfunction

autocmd FileType python,javascript call EnableAutoSpaces()
set cc=80

function! AutoSemiColon()
  " New lines with semicolon
  nnoremap <buffer> S S;<Esc>i
  nnoremap <buffer> o o;<Esc>i
  inoremap <buffer> <S-CR> <Esc>o;<Esc>i
  inoremap <buffer> <C-CR> <Esc>o

  function! MakeBlankIfOnlySemicolon()
    if match(getline("."), '\v^\s*;\s*$') != -1
      normal! S
    endif
  endfunction

  inoremap <buffer> <silent> <Esc> <Esc>:call MakeBlankIfOnlySemicolon()<CR>
endfunction

autocmd FileType javascript call AutoSemiColon()

autocmd FileType python iabbr <buffer> ! not
