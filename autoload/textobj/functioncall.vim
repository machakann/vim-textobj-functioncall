" textobj-functioncall
" Is there any better idea about the name?

" 'if' and 'af' behave differently when the cursor is on a string literal.
" 'if' can also recognize function calls inside the string literal.
" 'af' always ignore the string literal region.
" 'if' might not be always correct...

"                                 #              : cursor position
" call map(['1', '3', '2'], 'sugoi_func(v:val)')
"
"                            |<-------if------>|
" call map(['1', '3', '2'], 's:sugoi_func(v:val)')
"      |<------------------af------------------->|

let s:save_cpo = &cpo
set cpo&vim

let s:functioncall_patterns = {}
let s:functioncall_patterns['_'] = {
      \ 'header' : '\<\h\k*',
      \ 'footer' : '',
      \ 'bra'    : '(',
      \ 'ket'    : ')',
      \ }

let s:functioncall_patterns['vim'] = {
      \ 'header' : '\<\%(s:\)\?\k*',
      \ 'footer' : '',
      \ 'bra'    : '(',
      \ 'ket'    : ')',
      \ }

function! textobj#functioncall#i()
  return s:base_model('i')
endfunction

function! textobj#functioncall#a()
  return s:base_model('a')
endfunction

function! s:base_model(mode)  "{{{
  let l:count   = v:count1
  let orig_pos  = [line('.'), col('.')]
  let judge_syn = !s:is_string_literal(((a:mode == 'i') ? 1 : 0), orig_pos)

  " specify filetype-unique pattern
  let [header, bra, ket, footer] = s:resolve_patterns()

  let head    = header . bra
  let tail    = ket . footer
  let head_start = searchpos(head, 'bc', orig_pos[0])
  let head_end   = searchpos(head, 'ce', orig_pos[0])
  call cursor(orig_pos)
  let tail_start = searchpos(tail, 'bc', orig_pos[0])
  let tail_end   = searchpos(tail, 'ce', orig_pos[0])
"   PP! [orig_pos, head, head_start, head_end, tail, tail_start, tail_end]

  " start searching
  " check the initial position
  if (head_start != [0, 0]) && (head_end != [0, 0]) && (orig_pos[1] >= head_start[1]) && (orig_pos[1] <= head_end[1])
"     PP! 1
    " cursor is on a header
    call cursor(head_end)
  elseif (tail_start != [0, 0]) && (tail_end != [0, 0]) && (orig_pos[1] >= tail_start[1]) && (orig_pos[1] <= tail_end[1]) && !s:is_string_literal(judge_syn, tail_end)
"     PP! 2
    " cursor is on a footer
    call cursor(tail_start)

    if tail_start[1] != 1
      normal! h
    endif
  else
"     PP! 3
    call cursor(orig_pos)
  endif

  let loop = 0
  let flag = 'bc'
  while loop < l:count
    " search for a head pattern
    let bra_pos = searchpairpos(bra, '', ket, flag, 's:is_string_literal(judge_syn, [line("."), col(".")])', orig_pos[0])

    if bra_pos == [0, 0]
      " cannot find
"       PP! 'cannot find head pos'
      return 0
    endif

    " 'c' flag is necessary only for the first loop
    let flag = 'b'

    if !s:is_string_literal(judge_syn, bra_pos)
      " 'bra' should accompany with 'header'
      if searchpos(head, 'bcen', orig_pos[0]) == bra_pos
        let head_pos = searchpos(head, 'bc', orig_pos[0])
"         PP! ['head_pos', head_pos]
        let loop += 1
"         PP! [loop, l:count]
      endif
    endif
  endwhile

  " Start searching for the paired tail pattern.
  " update the syntax information of head
  let judge_syn = (!s:is_string_literal(((a:mode == 'i') ? 1 : 0), head_pos))

  " move to 'bra'
  normal! f(

  while 1
    " search for the paired 'ket'
    if searchpairpos(bra, '', ket, 'W', 's:is_string_literal(judge_syn, [line("."), col(".")])') == [0, 0]
      " cannot found
"       PP! 'cannot find tail_pos'
      return 0
    endif

    let tail_pos = searchpos(tail, 'cenW')
"     PP! ['head_pos', head_pos, 'tail_pos', tail_pos]
    if tail_pos == [0, 0]
      continue
    elseif !s:is_string_literal(judge_syn, tail_pos)
      " found the corresponded tail
"       PP! ['successfully found!', 'head_pos', head_pos, 'tail_pos', tail_pos]
      break
    endif
  endwhile


  return ['v', [0] + head_pos + [0], [0] + tail_pos + [0]]
endfunction
"}}}
function! s:is_string_literal(flag, pos)  "{{{
  if a:flag
    return synIDattr(synIDtrans(synID(a:pos[0], a:pos[1], 1)), "name") =~# 'String'
  else
    return 0
  endif
endfunction
"}}}
function! s:resolve_patterns()  "{{{
  let filetype = match(keys(s:functioncall_patterns), &filetype) < 0 ? '_' : &filetype
  let dict     = s:functioncall_patterns[filetype]
  return [dict['header'], dict['bra'], dict['ket'], dict['footer']]
endfunction
"}}}


let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set foldmethod=marker:
" vim:set commentstring="%s:
