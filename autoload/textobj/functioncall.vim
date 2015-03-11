" textobj-functioncall
" Is there any better idea about the name?

" TODO: Embedded comment should be ignored

let s:save_cpo = &cpo
set cpo&vim

let s:type_list = type([])
let s:type_dict = type({})
let s:null_pos  = [0, 0]

" default patterns
let s:patterns = {}
let s:patterns['_'] = [
      \   {
      \     'header' : '\<\h\k*',
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

let s:patterns['vim'] = [
      \   {
      \     'header' : '\<\%(s:\)\?\k*',
      \     'bra'    : '(',
      \     'ket'    : ')',
      \     'footer' : '',
      \   },
      \   {
      \     'header' : '\%(^\|[^:]\)\zs\<\%([abglstvw]:\)\?\h\k*',
      \     'bra'    : '\[',
      \     'ket'    : '\]',
      \     'footer' : '',
      \   },
      \ ]

function! textobj#functioncall#i() abort
  return s:base_model('i')
endfunction

function! textobj#functioncall#a() abort
  return s:base_model('a')
endfunction

function! textobj#functioncall#ip() abort
  return s:base_model('ip')
endfunction

function! textobj#functioncall#ap() abort
  return s:base_model('ap')
endfunction

function! s:base_model(mode) abort  "{{{
  let l:count = v:count1

  " user settings
  let opt = {}
  let opt.search_lines = s:user_conf('search_lines' , 30)

  " pattern-assignment
  let pattern_list = s:resolve_patterns()

  let view = winsaveview()
  try
    let candidates = s:gather_candidates(a:mode, l:count, pattern_list, opt)
    if a:mode[0] ==# 'a' && candidates == []
      let candidates = s:gather_candidates('i', l:count, pattern_list, opt)
    endif
  finally
    call winrestview(view)
  endtry

  if candidates == []
    return 0
  else
    let line_numbers = map(copy(candidates), 'v:val[0][0]') + map(copy(candidates), 'v:val[3][0]')
    let top_line     = min(line_numbers)
    let bottom_line  = max(line_numbers)

    let sorted_candidates = s:sort_candidates(candidates, top_line, bottom_line)
    if len(sorted_candidates) > l:count - 1
      let [head_pos, bra_pos, ket_pos, tail_pos, _, _] = sorted_candidates[l:count - 1]
    else
      return 0
    endif

    if a:mode[1] ==# 'p'
      if bra_pos == ket_pos || (bra_pos[0] == ket_pos[0] && bra_pos[1]+1 == ket_pos[1]-1)
        return 0
      else
        return ['v', [0, bra_pos[0], bra_pos[1]+1, 0], [0, ket_pos[0], ket_pos[1]-1, 0]]
      endif
    else
      return ['v', [0] + head_pos + [0], [0] + tail_pos + [0]]
    endif
  endif
endfunction
"}}}
function! s:gather_candidates(mode, count, pattern_list, opt) abort  "{{{
  let orig_pos = getpos('.')[1:2]

  " searching range limitation
  let fileend = line('$')
  if a:opt.search_lines < 0
    let upper_line = 1
    let lower_line = fileend
  else
    let upper_line = orig_pos[0] - a:opt.search_lines
    let upper_line = upper_line < 1 ? 1 : upper_line
    let lower_line = orig_pos[0] + a:opt.search_lines
    let lower_line = lower_line > fileend ? fileend : lower_line
  endif

  let rank       = 0
  let candidates = []
  for pattern in a:pattern_list
    let rank += 1
    let header = pattern.header
    let bra    = pattern.bra
    let ket    = pattern.ket
    let footer = pattern.footer

    let loop = 0
    let head = header . bra
    let tail = ket . footer

    " start searching
    if a:mode[0] ==# 'a'
      " search for the first 'bra'
      if searchpos(tail, 'cn', lower_line) == orig_pos
        let bra_pos = searchpairpos(bra, '', ket, 'b', '', upper_line)
      endif
      let bra_pos = searchpairpos(bra, '', ket, 'b', '', upper_line)
      let is_string_at_bra = s:is_string_literal(bra_pos)
    elseif a:mode[0] ==# 'i'
      let head_start = searchpos(head, 'bc', upper_line)
      let head_end   = searchpos(head, 'ce', lower_line)
      call cursor(orig_pos)
      let tail_start = searchpos(tail, 'bc', upper_line)
      let tail_end   = searchpos(tail, 'ce', lower_line)

      " check the initial position
      if s:is_in_the_range(orig_pos, head_start, head_end)
        " cursor is on a header
        call cursor(head_end)
      elseif s:is_in_the_range(orig_pos, tail_start, tail_end)
        " cursor is on a footer
        call cursor(tail_start)
        if tail_start[1] != 1
          normal! h
        endif
      else
        " cursor is in between a bra and a ket
        call cursor(orig_pos)
      endif

      " move to the corresponded 'bra'
      let bra_pos = searchpairpos(bra, '', ket, 'bc', '', upper_line)
      if bra_pos == s:null_pos | continue | endif
      let is_string_at_bra = s:is_string_literal(bra_pos)
    endif

    while loop < a:count
      " 'bra' should accompany with 'header'
      if searchpos(head, 'bcen', upper_line) == bra_pos
        let head_pos = searchpos(head, 'bcn', upper_line)

        " search for the paired 'ket'
        let ket_pos = searchpairpos(bra, '', ket, '', 's:is_string_literal(getpos(".")[1:2]) != is_string_at_bra', lower_line)
        if ket_pos != s:null_pos
          let tail_pos = searchpos(tail, 'ce', lower_line)
          if tail_pos == s:null_pos
            break
          elseif searchpos(tail, 'bcn', upper_line) == ket_pos
            " syntax check
            if !is_string_at_bra || s:is_continuous_syntax(bra_pos, ket_pos)
              " found the corresponded tail
              let candidates += [[head_pos, bra_pos, ket_pos, tail_pos, rank]]
              let loop += 1
            endif
          endif
        endif
        call cursor(bra_pos)
      endif

      " move to the next 'bra'
      let bra_pos = searchpairpos(bra, '', ket, 'b', '', upper_line)
      if bra_pos == s:null_pos | break | endif
      let is_string_at_bra = s:is_string_literal(bra_pos)
    endwhile

    call cursor(orig_pos)
  endfor
  return candidates
endfunction
"}}}
function! s:is_in_the_range(pos, head, tail) abort  "{{{
  return (a:pos != s:null_pos) && (a:head != s:null_pos) && (a:tail != s:null_pos)
    \  && ((a:pos[0] > a:head[0]) || ((a:pos[0] == a:head[0]) && (a:pos[1] >= a:head[1])))
    \  && ((a:pos[0] < a:tail[0]) || ((a:pos[0] == a:tail[0]) && (a:pos[1] <= a:tail[1])))
endfunction
"}}}
function! s:is_string_literal(pos) abort  "{{{
  return match(map(synstack(a:pos[0], a:pos[1]), 'synIDattr(synIDtrans(v:val), "name")'), 'String') > -1
endfunction
"}}}
function! s:is_continuous_syntax(bra_pos, ket_pos) abort  "{{{
  let start_col = a:bra_pos[1]
  for lnum in range(a:bra_pos[0], a:ket_pos[0])
    if lnum == a:ket_pos[0]
      let end_col= a:ket_pos[1]
    else
      let end_col= col([lnum, '$'])
    endif
    for col in range(start_col, end_col)
      if match(map(synstack(lnum, col), 'synIDattr(synIDtrans(v:val), "name")'), 'String') < 0
        return 0
      endif
    endfor
    let start_col = 1
  endfor
  return 1
endfunction
"}}}
function! s:user_conf(name, default) abort    "{{{
  let user_conf = a:default

  if exists('g:textobj_functioncall_' . a:name)
    let user_conf = g:textobj_functioncall_{a:name}
  endif

  if exists('t:textobj_functioncall_' . a:name)
    let user_conf = t:textobj_functioncall_{a:name}
  endif

  if exists('w:textobj_functioncall_' . a:name)
    let user_conf = w:textobj_functioncall_{a:name}
  endif

  if exists('b:textobj_functioncall_' . a:name)
    let user_conf = b:textobj_functioncall_{a:name}
  endif

  return user_conf
endfunction
"}}}
function! s:resolve_patterns() abort  "{{{
  if exists('g:textobj_functioncall_patterns')
    let pattern_dict = g:textobj_functioncall_patterns
    if has_key(pattern_dict, &filetype)
      return pattern_dict[&filetype]
    elseif has_key(pattern_dict, '_')
      return pattern_dict['_']
    endif
  endif

  let pattern_dict = s:patterns
  if has_key(pattern_dict, &filetype)
    return pattern_dict[&filetype]
  else
    return pattern_dict['_']
  endif
endfunction
"}}}
function! s:sort_candidates(candidates, top_line, bottom_line) abort  "{{{
  let length_list = map(getline(a:top_line, a:bottom_line), 'len(v:val) + 1')

  let idx = 0
  let accummed_length = 0
  let accummed_list   = [0]
  for length in length_list[1:]
    let accummed_length  = accummed_length + length_list[idx]
    let accummed_list   += [accummed_length]
    let idx += 1
  endfor

  " candidates == [[head_pos], [bra_pos], [head_pos], [tail_pos], rank, distance]
  let candidates = map(copy(a:candidates), '[v:val[0], v:val[1], v:val[2], v:val[3], v:val[4], ((accummed_list[v:val[3][0] - a:top_line] - v:val[0][1] + 1) + v:val[3][1])]')

  return sort(candidates, 's:compare')
endfunction
"}}}
function! s:compare(i1, i2) abort "{{{
  if a:i1[5] < a:i2[5]
    return -1
  elseif a:i1[5] > a:i2[5]
    return 1
  else
    return a:i2[4] - a:i1[4]
  endif
endfunction
"}}}

" utilities
function! s:create_key(filetype) abort  "{{{
  if !exists('g:textobj_functioncall_patterns')
    let g:textobj_functioncall_patterns = deepcopy(s:patterns)
  endif
  if !has_key(g:textobj_functioncall_patterns, a:filetype)
    if has_key(g:textobj_functioncall_patterns, '_')
      let g:textobj_functioncall_patterns[a:filetype] = deepcopy(g:textobj_functioncall_patterns['_'])
    else
      if has_key(s:patterns, a:filetype)
        let g:textobj_functioncall_patterns[a:filetype] = deepcopy(s:patterns[a:filetype])
      else
        let g:textobj_functioncall_patterns[a:filetype] = deepcopy(s:patterns['_'])
      endif
    endif
  endif
endfunction
"}}}
function! textobj#functioncall#add(header, bra, ket, footer, ...) abort "{{{
  if a:bra ==# ''
    echoerr 'textobj-functincall:textobj#functioncall#add: The second argument cannot be empty.'
    return
  elseif a:ket ==# ''
    echoerr 'textobj-functincall:textobj#functioncall#add: The third argument cannot be empty.'
    return
  endif

  let filetype = a:0 > 0 ? a:1
             \ : &filetype != '' ? &filetype
             \ : '_'
  call s:create_key(filetype)

  let g:textobj_functioncall_patterns[filetype] += [{
        \ 'header': a:header,
        \ 'bra'   : a:bra,
        \ 'ket'   : a:ket,
        \ 'footer': a:footer,
        \ }]
endfunction
"}}}
function! textobj#functioncall#clear(...) abort "{{{
  let filetype = a:0 > 0 ? a:1
             \ : &filetype != '' ? &filetype
             \ : '_'
  call create_key(filetype)
  let g:textobj_functioncall_patterns[filetype] = []
endfunction
"}}}
function! textobj#functioncall#include(target, ...) abort "{{{
  let dest = a:0 > 0 ? a:1
         \ : &filetype != '' ? &filetype
         \ : '_'
  let included = has_key(g:textobj_functioncall_patterns, a:target)
             \ ? deepcopy(g:textobj_functioncall_patterns[a:target])
             \ : []
  call s:create_key(dest)
  let g:textobj_functioncall_patterns[dest] += included
endfunction
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set foldmethod=marker:
" vim:set commentstring="%s:
