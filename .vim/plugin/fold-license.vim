function! FoldLicense()
    let license_line = searchpos("\\vRedistribution and use in source and binary forms|This library is free software; you can redistribute it and/or", "n")[0]
    if license_line == 0
        " No license in this file
        return
    endif

    let previous_position = getpos(".")
    call cursor(license_line - 1, 1)
    normal! V}zf
    call setpos(".", previous_position)
endfunction

augroup FoldLicense
    autocmd BufNewFile,BufReadPost *.h,*.hpp,*.c,*.cpp call FoldLicense()
augroup END
