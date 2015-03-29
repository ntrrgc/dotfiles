setlocal sw=2 ts=2
iabbrev <buffer> log console.log
iabbrev <buffer> exp module.exports

"<TAB> Conflicts with UltiSnips
"inoremap <buffer> <expr><TAB> pumvisible() ? "\<C-n>" : "\<TAB>"
