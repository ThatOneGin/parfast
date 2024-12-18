" parfast.vim
" syntax file for parfast
" dont working, i really dont know vimscript

syntax clear

hi def link parfast_key Keyword
hi def link parfast_str String
hi def link parfast_comment Comment
hi def link parfast_number Number

syntax enable

syntax match parfast_key /\v\<(if|else|include|while|macro|end|endm)\>/
syntax match parfast_str /".*"/
syntax match parfast_comment /\/\/.*/
syntax match parfast_number /\v\d+(\.\d+)?/

" filetype recognition

augroup filetypedetect
  autocmd!
  autocmd BufNewFile,BufRead *.parfast setf parfast
augroup END
