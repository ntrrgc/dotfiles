setlocal sw=4 ts=8 autoindent

" Barry Arthur, 2014-07-02
" Example user-completion function for "Robot framework syntax"

function! CompleteWordSets(findstart, base)
  if a:findstart
    let line = getline('.')
    let start = col('.') - 1
    return match(line[:start], '\(.*\s\{2,}\)\?\zs.\{-}\>$')
  else
    let base = matchstr(a:base, '\(.*\s\{2,}\)\?\zs.\{-}\>$')
    let res = []
    for l in getline(1, '$')
      for ws in split(l, '\s\{2,}')
        if ws =~ '^' . base
          call add(res, ws)
        endif
      endfor
    endfor
    return res
  endif
endfunction

" Neocomplete is used instead of this:
"setlocal completefunc=CompleteWordSets
