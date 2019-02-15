if exists("b:did_ftplugin_textobj_functioncall")
  finish
endif
let b:did_ftplugin_textobj_functioncall = 1

let s:save_cpo = &cpo
set cpo-=C

" To include multibyte characters
let b:textobj_functioncall_patterns = [
  \   {
  \     'header' : '\%#=2\<[[:upper:][:lower:]_]\k*!\?',
  \     'bra'    : '(',
  \     'ket'    : ')',
  \     'footer' : '',
  \   },
  \   {
  \     'header' : '\%#=2\<[[:upper:][:lower:]_]\k*',
  \     'bra'    : '\[',
  \     'ket'    : '\]',
  \     'footer' : '',
  \   },
  \ ]

let &cpo = s:save_cpo
unlet s:save_cpo
