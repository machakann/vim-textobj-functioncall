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
      \     'header' : '\C\<\%(\h\|[sa]:\h\|g:[A-Z]\)\k*',
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

" To include multibyte characters
let s:patterns['julia'] = [
      \   {
      \     'header' : '\%#=2\<[[:upper:][:lower:]_]\k*',
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
    let range = s:get_range(a:mode, l:count, candidates)
  finally
    call winrestview(view)
  endtry
  call s:select(a:mode, range)
endfunction
"}}}
function! s:gather_candidates(mode, count, pattern_list, opt) abort  "{{{
  let orig_pos = getpos('.')[1:2]

  " searching range limitation
  if a:opt.search_lines < 0
    let upper_line = 1
    let lower_line = line('$')
  else
    let upper_line = max([1, orig_pos[0] - a:opt.search_lines])
    let lower_line = min([orig_pos[0] + a:opt.search_lines, line('$')])
  endif

  let rank = 0
  let candidates = []
  for pattern in a:pattern_list
    let rank += 1
    call s:search_pattern(candidates, pattern, a:mode, a:count, rank, orig_pos, upper_line, lower_line)
    call cursor(orig_pos)
  endfor
  return a:mode[0] ==# 'a' && candidates == []
        \ ? s:gather_candidates('i', a:count, a:pattern_list, a:opt)
        \ : candidates
endfunction
"}}}
function! s:search_pattern(candidates, pattern, mode, count, rank, orig_pos, upper_line, lower_line) abort "{{{
  let candidates = []
  let header = a:pattern.header
  let bra    = a:pattern.bra
  let ket    = a:pattern.ket
  let footer = a:pattern.footer

  let loop = 0
  let head = header . bra
  let tail = ket . footer

  let bra_pos = s:search_key_bra(a:mode, a:orig_pos, bra, ket, head, tail, a:upper_line, a:lower_line)
  if bra_pos == s:null_pos | return [] | endif
  let is_string_at_bra = s:is_string_literal(bra_pos)

  while loop < a:count
    " 'bra' should accompany with 'header'
    if searchpos(head, 'bcen', a:upper_line) == bra_pos
      let head_pos = searchpos(head, 'bcn', a:upper_line)

      " search for the paired 'ket'
      let ket_pos = searchpairpos(bra, '', ket, '', 's:is_string_literal(getpos(".")[1:2]) != is_string_at_bra', a:lower_line)
      if ket_pos != s:null_pos
        let tail_pos = searchpos(tail, 'ce', a:lower_line)
        if tail_pos == s:null_pos
          break
        elseif searchpos(tail, 'bcn', a:upper_line) == ket_pos
          " syntax check
          if !is_string_at_bra || s:is_continuous_syntax(bra_pos, ket_pos)
            " found the corresponded tail
            call add(a:candidates, [head_pos, bra_pos, ket_pos, tail_pos, a:rank, s:get_buf_length(head_pos, tail_pos)])
            let loop += 1
          endif
        endif
      endif
      call cursor(bra_pos)
    endif

    " move to the next 'bra'
    let bra_pos = searchpairpos(bra, '', ket, 'b', '', a:upper_line)
    if bra_pos == s:null_pos | break | endif
    let is_string_at_bra = s:is_string_literal(bra_pos)
  endwhile
  return candidates
endfunction
"}}}
function! s:search_key_bra(mode, orig_pos, bra, ket, head, tail, upper_line, lower_line) abort  "{{{
  let bra_pos = s:null_pos
  if a:mode[0] ==# 'a'
    " search for the first 'bra'
    if searchpos(a:tail, 'cn', a:lower_line) == a:orig_pos
      let bra_pos = searchpairpos(a:bra, '', a:ket, 'b', '', a:upper_line)
    endif
    let bra_pos = searchpairpos(a:bra, '', a:ket, 'b', '', a:upper_line)
  elseif a:mode[0] ==# 'i'
    let head_start = searchpos(a:head, 'bc', a:upper_line)
    let head_end   = searchpos(a:head, 'ce', a:lower_line)
    call cursor(a:orig_pos)
    let tail_start = searchpos(a:tail, 'bc', a:upper_line)
    let tail_end   = searchpos(a:tail, 'ce', a:lower_line)

    " check the initial position
    if s:is_in_the_range(a:orig_pos, head_start, head_end)
      " cursor is on a header
      call cursor(head_end)
    elseif s:is_in_the_range(a:orig_pos, tail_start, tail_end)
      " cursor is on a footer
      call cursor(tail_start)
      if tail_start[1] != 1
        normal! h
      endif
    else
      " cursor is in between a bra and a ket
      call cursor(a:orig_pos)
    endif

    " move to the corresponded 'bra'
    let bra_pos = searchpairpos(a:bra, '', a:ket, 'bc', '', a:upper_line)
  endif
  return bra_pos
endfunction
"}}}
function! s:get_range(mode, count, candidates) abort "{{{
  let head = copy(s:null_pos)
  let tail = copy(s:null_pos)
  if a:candidates != []
    let line_numbers = map(copy(a:candidates), 'v:val[0][0]') + map(copy(a:candidates), 'v:val[3][0]')
    let top_line     = min(line_numbers)
    let bottom_line  = max(line_numbers)

    let sorted_candidates = s:sort_candidates(a:candidates, top_line, bottom_line)
    if len(sorted_candidates) > a:count - 1
      let [head_pos, bra_pos, ket_pos, tail_pos, _, _] = sorted_candidates[a:count - 1]
      if a:mode[1] ==# 'p'
        if !(bra_pos == ket_pos || (bra_pos[0] == ket_pos[0] && bra_pos[1]+1 == ket_pos[1]-1))
          let [head, tail] = s:get_narrower_region(bra_pos, ket_pos)
        endif
      else
        let head = head_pos
        let tail = tail_pos
      endif
    endif
  endif
  return [head, tail]
endfunction
"}}}
function! s:select(mode, range) abort  "{{{
  let [head, tail] = a:range
  if head != s:null_pos && tail != s:null_pos
    " select textobject
    if a:mode ==# "\<C-v>"
      execute "normal! \<C-v>"
    else
      normal! v
    endif

    call cursor(head)
    normal! o
    call cursor(tail)

    " counter measure for the 'selection' option being 'exclusive'
    if &selection ==# 'exclusive'
      normal! l
    endif
  else
    if a:mode ==# 'x'
      normal! gv
    endif
  endif
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
  let pattern_dict = get(g:, 'textobj_functioncall_patterns', s:patterns)
  if has_key(pattern_dict, &filetype)
    return pattern_dict[&filetype]
  else
    return pattern_dict['_']
  endif
endfunction
"}}}
function! s:get_narrower_region(head_edge, tail_edge) abort "{{{
  let whichwrap  = &whichwrap
  let &whichwrap = 'h,l'
  try
    call cursor(a:head_edge)
    normal! l
    let head = getpos('.')[1:2]
    call cursor(a:tail_edge)
    normal! h
    let tail = getpos('.')[1:2]
  finally
    let &whichwrap = whichwrap
  endtry
  return [head, tail]
endfunction
"}}}
function! s:sort_candidates(candidates, top_line, bottom_line) abort  "{{{
  " NOTE: candidates == [[head_pos], [bra_pos], [ket_pos], [tail_pos], rank, distance]
  call filter(a:candidates, 'v:val[0] != s:null_pos && v:val[1] != s:null_pos && v:val[2] != s:null_pos && v:val[3] != s:null_pos')
  return sort(a:candidates, 's:compare')
endfunction
"}}}
function! s:get_buf_length(start, end) abort  "{{{
  if a:start[0] == a:end[0]
    let len = a:end[1] - a:start[1] + 1
  else
    let len = (line2byte(a:end[0]) + a:end[1]) - (line2byte(a:start[0]) + a:start[1]) + 1
  endif
  return len
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
function! s:filetypekey() abort "{{{
  return &filetype !=# '' ? &filetype : '_'
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

  let filetype = a:0 > 0 ? a:1 : s:filetypekey()
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
  let filetype = a:0 > 0 ? a:1 : s:filetypekey()
  call s:create_key(filetype)
  let g:textobj_functioncall_patterns[filetype] = []
endfunction
"}}}
function! textobj#functioncall#include(target, ...) abort "{{{
  let filetype = a:0 > 0 ? a:1 : s:filetypekey()
  let included = has_key(g:textobj_functioncall_patterns, a:target)
             \ ? deepcopy(g:textobj_functioncall_patterns[a:target])
             \ : []
  call s:create_key(filetype)
  let g:textobj_functioncall_patterns[filetype] += included
endfunction
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set foldmethod=marker:
" vim:set commentstring="%s:
