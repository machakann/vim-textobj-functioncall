" Vim global plugin to define text-object for function call.
" Last Change: 13-Apr-2014.
" Maintainer : Masaaki Nakamura <mckn@outlook.com>

" License    : NYSL
"              Japanese <http://www.kmonos.net/nysl/>
"              English (Unofficial) <http://www.kmonos.net/nysl/index.en.html>

if exists("g:loaded_textobj_functioncall")
  finish
endif
let g:loaded_functioncall = 1

call textobj#user#plugin('functioncall', {
      \   '-': {
      \     'select-a-function': 'textobj#functioncall#a',
      \     'select-a': 'af',
      \     'select-i-function': 'textobj#functioncall#i',
      \     'select-i': 'if',
      \   },
      \ })

