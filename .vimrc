set nocompatible
set linebreak ts=4 sw=4 expandtab
set number relativenumber
let mapleader='`'
filetype off

if has('unnamedplus')
    set clipboard=unnamedplus
else
    set clipboard=unnamed
endif

function! Strip(input_string)
    return substitute(a:input_string, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunction

function! SystemName()
  let lsb = readfile("/etc/lsb-release")
  let lsb_data = {}
  for line in lsb
    let line_data = split(line, "=")
    let key = Strip(line_data[0])
    let value = Strip(line_data[1])
    let value = substitute(value, '"', '', 'g')
    let lsb_data[key] = value
  endfor

  return lsb_data['DISTRIB_ID']
endfunction
let system_name = SystemName()

if has('gui_running')
    set guioptions-=T
    colorscheme django

    set guifont=Ubuntu\ Mono\ 12
    colorscheme jellybeans

    " Vim 7.3 mouse bug workaround
    set nomousehide

    " If gvim has just been executed, set width and height, but do not if
    " vimrc has been sourced.
    if ! exists("g:vimrc_sourced")
        set lines=34 columns=120
        let g:vimrc_sourced=1
    endif
else
    set background=dark
    set mouse=a
endif

noremap Q <nop>
command W w !sudo tee >/dev/null %
noremap <C-s> :w<CR>

set rtp+=~/.vim/bundle/vundle/
call vundle#rc()
Bundle 'gmarik/vundle'

" NERDTree
map <F3> :NERDTreeToggle<Return>
let NERDTreeChDirMode=2
let NERDTreeIgnore=['\.pyc$', '__pycache__', '\~$']
Bundle 'scrooloose/nerdtree'

" Syntastic
"let g:syntastic_always_populate_loc_list=1
"Bundle 'scrooloose/syntastic'

" Pydiction
"let g:pydiction_location = '/home/ntrrgc/.vim/bundle/Pydiction/complete-dict'
"Bundle 'vim-scripts/Pydiction'

" pyref
let g:pyref_mapping = 'K'
let g:pyref_python = '/opt/python-3.3.3-docs-html'
let g:pyref_django = '/opt/django-1.6-docs-html'
Bundle 'xolox/vim-misc'
Bundle 'xolox/vim-pyref'

" Emmet
let g:user_emmet_install_global = 0
if has('gui_running')
  let g:user_emmet_expandabbr_key='<c-space>'
endif
let g:user_emmet_balancetagoutward_key='<c-d>'
let g:user_emmet_balancetaginward_key='<c-e>'
inoremap <C-@> <C-Space>
autocmd FileType html,css EmmetInstall
Bundle 'mattn/emmet-vim'

" UltiSnips
let g:UltiSnipsEditSplit="horizontal"
let g:UltiSnipsExpandTrigger="<Tab>"
let g:UltiSnipsJumpForwardTrigger="<Tab>"
let g:UltiSnipsJumpBackwardTrigger="<S-Tab>"
Bundle 'SirVer/ultisnips'

" vim-pasta
Bundle 'sickill/vim-pasta'

" vim-angry
Bundle 'b4winckler/vim-angry'

" DrawIt
Bundle 'vim-scripts/DrawIt'

" Javascript
Bundle 'pangloss/vim-javascript'

" Better JSON
Bundle 'jakar/vim-json'

" Ansible
Bundle 'chase/vim-ansible-yaml'

" AutoPairs
let g:AutoPairsFlyMode = 0
let g:AutoPairsShortcutFastWrap = '<C-e>'
Bundle 'jiangmiao/auto-pairs'

filetype plugin indent on
syntax on
