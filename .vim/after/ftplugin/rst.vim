setlocal linebreak sw=4 autoindent

noremap <buffer> k gk
noremap <buffer> j gj

setlocal iskeyword+=127-255
setlocal spell spelllang=en_us

call ActivateAutomaticTitle()
