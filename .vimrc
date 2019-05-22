set nocompatible
set linebreak ts=4 sw=4 expandtab
set number relativenumber
let mapleader='\'
set completeopt=menuone
set foldlevel=20

set nofixeol

" italics in gnome-terminal
set t_ZH=[3m
set t_ZR=[23m

filetype off

if has('unnamedplus') || has('nvim') " workaround https://github.com/neovim/neovim/issues/6103
    set clipboard=unnamedplus
else
    set clipboard=unnamed
endif

function! Strip(input_string)
    return substitute(a:input_string, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunction

function! SystemName()
  if !filereadable("/etc/lsb-release")
    return "unknown"
  endif

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

    if system_name == 'Ubuntu'
      set guifont=Ubuntu\ Mono\ 12
      colorscheme jellybeans
    else
      set guifont=DejaVu\ Sans\ Mono\ 11
      colorscheme jellybeans
    endif

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
  "This is nice until you touch someone else code and you end up committing
  "whitespace changes.
  "autocmd BufWritePre *.py,*.js,*.coffee,*.rst :call <SID>StripTrailingWhitespaces()
augroup END

set rtp+=~/.vim/bundle/vundle/
call vundle#rc()
Plugin 'gmarik/vundle'

" NERDTree
map <F3> :NERDTreeToggle<Return>
let NERDTreeChDirMode=2
let NERDTreeIgnore=['\.pyc$', '__pycache__', '\~$']
Plugin 'scrooloose/nerdtree'

" Syntastic
"let g:syntastic_always_populate_loc_list=1
"Plugin 'scrooloose/syntastic'

"Plugin 'Valloric/YouCompleteMe'
let g:ycm_rust_src_path = substitute(system('rustc --print sysroot'), '\n\+$', '', '') . '/lib/rustlib/src/rust/src'
let g:ycm_extra_conf_globlist = [
            \ '/hdd/home/ntrrgc/Documentos/Dropbox/*', 
            \ '/hdd/home/ntrrgc/Documentos/Programas/*', 
            \ ]

" Always show the sign columns
autocmd BufEnter * sign define dummy
autocmd BufEnter * execute 'sign place 99999 line=1 name=dummy buffer=' . bufnr('')

Plugin 'rdnetto/YCM-Generator'

" pyref
let g:pyref_mapping = 'K'
let g:pyref_python = '/opt/python-3.3.3-docs-html'
let g:pyref_django = '/opt/django-1.6-docs-html'
Plugin 'xolox/vim-misc'
Plugin 'xolox/vim-pyref'

" Emmet
let g:user_emmet_install_global = 0
if has('gui_running')
  let g:user_emmet_expandabbr_key='<c-space>'
endif
"let g:user_emmet_balancetagoutward_key='<c-d>'
"let g:user_emmet_balancetaginward_key='<c-e>'
inoremap <C-@> <C-Space>
autocmd FileType html,htmldjango,css EmmetInstall
Plugin 'mattn/emmet-vim'

" UltiSnips
let g:UltiSnipsEditSplit="horizontal"
let g:UltiSnipsExpandTrigger="<Tab>"
let g:UltiSnipsJumpForwardTrigger="<Tab>"
let g:UltiSnipsJumpBackwardTrigger="<S-Tab>"
Plugin 'SirVer/ultisnips'

" vim-pasta
let g:pasta_disabled_filetypes = ['robot', 'text', 'renpy']
Plugin 'sickill/vim-pasta'

" vim-angry
Plugin 'b4winckler/vim-angry'

" DrawIt
Plugin 'vim-scripts/DrawIt'

" Javascript
Plugin 'pangloss/vim-javascript'

" Better JSON
Plugin 'jakar/vim-json'

" Ansible
Plugin 'chase/vim-ansible-yaml'

" AutoPairs
let g:AutoPairsFlyMode = 0
let g:AutoPairsShortcutFastWrap = '<C-e>'
let g:AutoPairsMapBS = 0
let g:TypeOnBackSpace = "\<C-R>=AutoPairsDelete()\<CR>"
Plugin 'yukunlin/auto-pairs'

" vim-fugitive (git integration)
Plugin 'tpope/vim-fugitive'

" No artifacts
" Disabled due to https://github.com/vim/vim/issues/1928 :(
"set lazyredraw

Plugin 'junegunn/vader.vim'

Plugin 'alfredodeza/pytest.vim'

Plugin 'mfukar/robotframework-vim'

Plugin 'tpope/vim-surround'
"
" CoffeeScript
Plugin 'kchmck/vim-coffee-script'

Plugin 'groenewege/vim-less'

Plugin 'vim-scripts/spec.vim'

" Git hot keys
map <C-M-s> :Gwrite<CR>:Gstatus<CR>:res +15<CR><C-n>
map <C-M-c> :Gcommit<CR>i

if filereadable(expand("~/.vimrc_local"))
  source ~/.vimrc_local
endif

Plugin 'kien/ctrlp.vim'
let g:ctrlp_custom_ignore = '\v[\/](node_modules|target|dist|env|output)|(\.(swp|ico|git|svn|DS_Store|pyc|pyo))$'

augroup sxhkdrc
autocmd BufWritePost sxhkdrc silent !pkill -x -USR1 sxhkd
augroup END

Plugin 'vim-ruby/vim-ruby'
Plugin 'scrooloose/nerdcommenter'
Plugin 'dag/vim-fish'
if &shell =~# 'fish$'
    set shell=bash
endif

Plugin 'chaimleib/vim-renpy'
Plugin 'leafgarland/typescript-vim'

Plugin 'MicahElliott/Rocannon' "ansible

Plugin 'keith/swift.vim'

Plugin 'rust-lang/rust.vim'

Plugin 'udalov/kotlin-vim'

Plugin 'tpope/vim-sleuth'

"Plugin 'ntpeters/vim-better-whitespace'

set laststatus=2

set incsearch hlsearch

set ts=8
noremap <F6> :YcmCompleter GoTo<CR>

filetype plugin indent on
syntax on
