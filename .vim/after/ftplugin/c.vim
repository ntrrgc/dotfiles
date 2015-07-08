imap <C-Cr> <Esc>A;

function! GetType()
  py << EOF
def MyGetType():
  from ycm.client.command_request import CommandRequest
  req = CommandRequest('GetType', '')
  req.Start()
  return req.Response()

vim.vars['patata'] = MyGetType()
EOF
  return g:patata
endfunction


function! DotOrArrow()
  let type = GetType()
  echom "Type".type
endfunction

"imap <expr> . DotOrArrow()
