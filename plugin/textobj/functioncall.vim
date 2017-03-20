" Vim global plugin to define text-object for function call.
" Last Change: 20-Mar-2017.
" Maintainer : Masaaki Nakamura <mckn@outlook.com>

" License    : NYSL
"              Japanese <http://www.kmonos.net/nysl/>
"              English (Unofficial) <http://www.kmonos.net/nysl/index.en.html>

if exists("g:loaded_textobj_functioncall")
  finish
endif
let g:loaded_textobj_functioncall = 1

onoremap <silent> <Plug>(textobj-functioncall-i)  :<C-u>call textobj#functioncall#i('o')<CR>
xnoremap <silent> <Plug>(textobj-functioncall-i)  :<C-u>call textobj#functioncall#i('x')<CR>
onoremap <silent> <Plug>(textobj-functioncall-a)  :<C-u>call textobj#functioncall#a('o')<CR>
xnoremap <silent> <Plug>(textobj-functioncall-a)  :<C-u>call textobj#functioncall#a('x')<CR>
onoremap <silent> <Plug>(textobj-functioncall-innerparen-i) :<C-u>call textobj#functioncall#ip('o')<CR>
xnoremap <silent> <Plug>(textobj-functioncall-innerparen-i) :<C-u>call textobj#functioncall#ip('x')<CR>
onoremap <silent> <Plug>(textobj-functioncall-innerparen-a) :<C-u>call textobj#functioncall#ap('o')<CR>
xnoremap <silent> <Plug>(textobj-functioncall-innerparen-a) :<C-u>call textobj#functioncall#ap('x')<CR>

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
