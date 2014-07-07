setlocal linebreak sw=4 autoindent
setlocal cc=
setlocal scrolloff=5

noremap <buffer> k gk
noremap <buffer> j gj
noremap <buffer> ^ g^
noremap <buffer> $ g$

setlocal iskeyword=32-47,91-96,123-126

call ActivateAutomaticTitle()
