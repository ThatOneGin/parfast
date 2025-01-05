" parfast.vim
" syntax highlight support for vim

if exists("b:current_syntax")
  finish
endif

syn keyword parfastKeyword if else while include end endm macro extern call elseif then do mem fn

syn match parfastComment "//.*$"

syn match parfastString /"\(.\|\n\)*?"/
syn match parfastString /"\(.\|\n\)*?"/

syn match parfastNumber /\v\d+(\.\d+)?/

hi def link parfastKeyword Keyword
hi def link parfastComment Comment
hi def link parfastString String
hi def link parfastNumber Number

let b:current_syntax = "parfast"

autocmd BufRead,BufNewFile *.parfast set filetype=parfast
