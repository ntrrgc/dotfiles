setlocal linebreak sw=4 autoindent
setlocal cc=
setlocal scrolloff=5
setlocal spell

noremap <buffer> k gk
noremap <buffer> j gj
noremap <buffer> ^ g^
noremap <buffer> $ g$

"setlocal iskeyword=32-47,91-96,123-126
set iskeyword+=128-255

call ActivateAutomaticTitle()

"inoremap <buffer> <Tab> <Esc>{{d}}jo<CR>

iabbrev ws WebSocket
iabbrev nt notificación
iabbrev nts notificaciones
iabbrev sb suscripción
iabbrev sbs subscripciones
iabbrev sv servidor
iabbrev svs servidores
iabbrev bd base de datos

if expand("%:p") =~ 'memoria'
  setlocal spelllang=es
else
  setlocal spelllang=en
endif
