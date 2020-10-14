function! DiffCopy()
pythonx << EOF

import vim

def GetRangeLines():
    buf = vim.current.buffer
    (lnum1, col1) = buf.mark('<')
    (lnum2, col2) = buf.mark('>')
    lines = vim.eval('getline({}, {})'.format(lnum1, lnum2))
    if len(lines) == 1:
        lines[0] = lines[0][col1:col2 + 1]
    else:
        lines[0] = lines[0][col1:]
        lines[-1] = lines[-1][:col2 + 1]
    return lines

def DiffCopyText():
    return "\n".join(
        line[1:]
        for line in GetRangeLines()
        if not line.startswith("-")
    )

vim.eval("setreg('+', '%s')" % DiffCopyText().replace("'", "''"))

EOF
endfunction

augroup DiffCopy
    autocmd BufReadPost *.patch :noremap <silent> <F8> :call DiffCopy()<CR>
augroup END
