if exists("b:did_ftplugin_textobj_functioncall")
  finish
endif
let b:did_ftplugin_textobj_functioncall = 1

let s:save_cpo = &cpo
set cpo-=C

let b:textobj_functioncall_patterns = [
  \   {
  \     'header' : '\<\h\k*[!?]\?',
  \     'bra'    : '(',
  \     'ket'    : ')',
  \     'footer' : '',
  \   },
  \   {
  \     'header' : '\<\h\k*',
  \     'bra'    : '\[',
  \     'ket'    : '\]',
  \     'footer' : '',
  \   },
  \ ]

let &cpo = s:save_cpo
unlet s:save_cpo
