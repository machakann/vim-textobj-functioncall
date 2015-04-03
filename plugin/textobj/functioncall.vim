" Vim global plugin to define text-object for function call.
" Last Change: 03-Apr-2015.
" Maintainer : Masaaki Nakamura <mckn@outlook.com>

" License    : NYSL
"              Japanese <http://www.kmonos.net/nysl/>
"              English (Unofficial) <http://www.kmonos.net/nysl/index.en.html>

if exists("g:loaded_textobj_functioncall")
  finish
endif
let g:loaded_textobj_functioncall = 1

onoremap <silent> <Plug>(textobj-functioncall-i)  :<C-u>call textobj#functioncall#i()<CR>
xnoremap <silent> <Plug>(textobj-functioncall-i)  :<C-u>call textobj#functioncall#i()<CR>
onoremap <silent> <Plug>(textobj-functioncall-a)  :<C-u>call textobj#functioncall#a()<CR>
xnoremap <silent> <Plug>(textobj-functioncall-a)  :<C-u>call textobj#functioncall#a()<CR>
onoremap <silent> <Plug>(textobj-functioncall-innerparen-i) :<C-u>call textobj#functioncall#ip()<CR>
xnoremap <silent> <Plug>(textobj-functioncall-innerparen-i) :<C-u>call textobj#functioncall#ip()<CR>
onoremap <silent> <Plug>(textobj-functioncall-innerparen-a) :<C-u>call textobj#functioncall#ap()<CR>
xnoremap <silent> <Plug>(textobj-functioncall-innerparen-a) :<C-u>call textobj#functioncall#ap()<CR>

""" default keymappings
" If g:textobj_delimited_no_default_key_mappings has been defined, then quit immediately.
if exists('g:textobj_functioncall_no_default_key_mappings') | finish | endif

if !hasmapto('<Plug>(textobj-functioncall-i)')
  silent! omap <unique> if <Plug>(textobj-functioncall-i)
  silent! xmap <unique> if <Plug>(textobj-functioncall-i)
endif

if !hasmapto('<Plug>(textobj-functioncall-a)')
  silent! omap <unique> af <Plug>(textobj-functioncall-a)
  silent! xmap <unique> af <Plug>(textobj-functioncall-a)
endif
