set nocompatible
set linebreak ts=4 sw=4 expandtab
set number relativenumber
let mapleader='`'
set completeopt=menuone
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
    set guioptions-=m
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
command! W w !sudo tee >/dev/null %
noremap <C-s> :w<CR>
noremap <F2> @q

" http://vimcasts.org/episodes/tidying-whitespace/
function! <SID>StripTrailingWhitespaces()
  " Preparation: save last search, and cursor position.
  let _s=@/
  let l = line(".")
  let c = col(".")
  " Do the business:
  %s/\s\+$//e
  " Clean up: restore previous search history, and cursor position
  let @/=_s
  call cursor(l, c)
endfunction

augroup vimrc
  autocmd BufWritePre *.py,*.js :call <SID>StripTrailingWhitespaces()
augroup END

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
"let g:user_emmet_balancetagoutward_key='<c-d>'
"let g:user_emmet_balancetaginward_key='<c-e>'
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
let g:pasta_disabled_filetypes = ['robot', 'text']
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
let g:AutoPairsMapBS = 0
let g:TypeOnBackSpace = "\<C-R>=AutoPairsDelete()\<CR>"
Bundle 'yukunlin/auto-pairs'

" vim-fugitive (git integration)
Bundle 'tpope/vim-fugitive'

if !exists('g:neocomplete#sources#omni#functions')
  let g:neocomplete#sources#omni#functions = {}
endif
let g:neocomplete#sources#omni#functions.robot = 'CompleteWordSets'

if !exists('g:neocomplete#sources#omni#input_patterns')
  let g:neocomplete#sources#omni#input_patterns = {}
endif
let g:neocomplete#sources#omni#input_patterns.robot = '.*'

" No artifacts
set lazyredraw
Bundle 'Shougo/neocomplete.vim'

" Disable AutoComplPop.
let g:acp_enableAtStartup = 0
" Use neocomplete.
let g:neocomplete#enable_at_startup = 1
" Use smartcase.
let g:neocomplete#enable_smart_case = 1
" Set minimum syntax keyword length.
let g:neocomplete#sources#syntax#min_keyword_length = 3
let g:neocomplete#lock_buffer_name_pattern = '\*ku\*'

autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags

" http://stackoverflow.com/a/18937785/1777162
" <CR>: close popup and open a new line.
inoremap <silent> <CR> <C-r>=<SID>my_cr_function()<CR>
function! s:my_cr_function()
  return neocomplete#smart_close_popup() . "\<CR>"
endfunction

Bundle 'junegunn/vader.vim'

Bundle 'alfredodeza/pytest.vim'

Bundle 'mfukar/robotframework-vim'

Bundle 'tpope/vim-surround'
"
" CoffeeScript
Bundle 'kchmck/vim-coffee-script'

if filereadable(expand("~/.vimrc_local"))
  source ~/.vimrc_local
endif

filetype plugin indent on
syntax on
