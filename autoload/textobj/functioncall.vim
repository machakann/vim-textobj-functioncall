" textobj-functioncall
" Is there any better idea about the name?

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

function! textobj#functioncall#i(mode) abort "{{{
  call s:common('i', a:mode)
endfunction
"}}}
function! textobj#functioncall#a(mode) abort "{{{
  call s:common('a', a:mode)
endfunction
"}}}
function! textobj#functioncall#ip(mode) abort "{{{
  call s:common('ip', a:mode)
endfunction
"}}}
function! textobj#functioncall#ap(mode) abort "{{{
  call s:common('ap', a:mode)
endfunction
"}}}
function! textobj#functioncall#new(patternlist, ...) abort "{{{
  let textobj = deepcopy(s:textobj)
  let textobj.patternlist = a:patternlist
  let searchlines = get(a:000, 0, -1)
  if searchlines < 0
    let textobj.stopline.top = 1
    let textobj.stopline.bottom = line('$')
  else
    let textobj.stopline.top = max([1, line('.') - searchlines])
    let textobj.stopline.bottom = min([line('.') + searchlines, line('$')])
  endif
  return textobj
endfunction
"}}}
function! s:common(kind, mode) abort "{{{
  let searchlines = s:user_conf('search_lines', 30)
  let patternlist = s:resolve_patterns()
  let textobj = textobj#functioncall#new(patternlist, searchlines)
  call textobj.select(a:kind, a:mode)
endfunction
"}}}
function! s:user_conf(name, default) abort    "{{{
  let user_conf = a:default
  if exists('g:textobj_functioncall_' . a:name)
    let user_conf = g:textobj_functioncall_{a:name}
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

" s:textobj{{{
let s:textobj = {
      \   'patternlist': [],
      \   'stopline': {'top': 0, 'bottom': 0}
      \ }
"}}}
function! s:textobj.select(kind, mode) dict abort  "{{{
  let visualmode = a:mode ==# 'x' && visualmode() ==# "\<C-v>" ? "\<C-v>" : 'v'
  let view = winsaveview()
  try
    let region = self.search(a:kind, a:mode, v:count1)
  finally
    call winrestview(view)
  endtry
  call s:select(a:mode, region)
endfunction
"}}}
function! s:textobj.search(kind, mode, ...) dict abort "{{{
  let l:count = get(a:000, 0, v:count1)
  let visualmode = get(a:000, 1, 'v')
  let candidates = s:gather_candidates(a:kind, a:mode, l:count, self.patternlist, self.stopline)
  let elected = s:elect(a:kind, l:count, candidates)
  return elected == {} ? {} : s:Region(a:kind, elected, visualmode)
endfunction
"}}}
function! s:Candidate(headpos, brapos, ketpos, tailpos, pattern, rank) abort "{{{
  return {
        \   'head': a:headpos,
        \   'bra': a:brapos,
        \   'ket': a:ketpos,
        \   'tail': a:tailpos,
        \   'pattern': a:pattern,
        \   'rank': a:rank,
        \   'len': s:get_buf_length(a:headpos, a:tailpos)
        \ }
endfunction
"}}}
function! s:Region(kind, candidate, type) abort "{{{
  if a:kind[1] ==# 'p'
    let [head, tail] = s:get_parameter_region(a:candidate)
  else
    let [head, tail] = [a:candidate.head, a:candidate.tail]
  endif
  return {'head': head, 'tail': tail, 'type': a:type}
endfunction
"}}}
function! s:gather_candidates(kind, mode, count, patternlist, stopline) abort  "{{{
  let rank = 0
  let cursorpos = getpos('.')[1:2]
  let candidates = []
  for pattern in a:patternlist
    let rank += 1
    let candidates += s:search_pattern(pattern, a:kind, a:mode, a:count, rank, cursorpos, a:stopline)
    call cursor(cursorpos)
  endfor
  return a:kind[0] ==# 'a' && candidates == []
        \ ? s:gather_candidates('i', a:mode, a:count, a:patternlist, a:stopline)
        \ : candidates
endfunction
"}}}
function! s:search_pattern(pattern, kind, mode, count, rank, cursorpos, stopline) abort "{{{
  let candidates = []
  let header = get(a:pattern, 'header', '')
  let bra    = a:pattern.bra
  let ket    = a:pattern.ket
  let footer = get(a:pattern, 'footer', '')

  let head = header . bra
  let tail = ket . footer

  let brapos = s:search_key_bra(a:kind, a:cursorpos, bra, ket, head, tail, a:stopline)
  if brapos == s:null_pos | return [] | endif
  let is_string_at_bra = s:is_string_literal(brapos)

  while len(candidates) < a:count
    " 'bra' should accompany with 'header'
    let headstart = searchpos(head, 'bc', a:stopline.top)
    let headend = searchpos(head, 'ce', a:stopline.bottom)
    call cursor(brapos)
    if s:is_in_the_range(brapos, headstart, headend)
      let headpos = headstart

      " search for the paired 'ket'
      let ketpos = searchpairpos(bra, '', ket, '', 's:is_string_literal(getpos(".")[1:2]) != is_string_at_bra', a:stopline.bottom)
      if ketpos != s:null_pos
        let tailpos = searchpos(tail, 'ce', a:stopline.bottom)
        if tailpos == s:null_pos
          break
        elseif searchpos(tail, 'bcn', a:stopline.top) == ketpos
          let candidate = s:Candidate(headpos, brapos, ketpos, tailpos, a:pattern, a:rank)
          if s:is_wide_enough(candidate, a:kind, a:mode) && s:is_syntax_ok(candidate, is_string_at_bra)
            " found the corresponded tail
            let candidates += [candidate]
          endif
        endif
      endif
      call cursor(brapos)
    endif

    " move to the next 'bra'
    let brapos = searchpairpos(bra, '', ket, 'b', '', a:stopline.top)
    if brapos == s:null_pos | break | endif
    let is_string_at_bra = s:is_string_literal(brapos)
  endwhile
  return candidates
endfunction
"}}}
function! s:search_key_bra(kind, cursorpos, bra, ket, head, tail, stopline) abort  "{{{
  let brapos = s:null_pos
  if a:kind[0] ==# 'a'
    " search for the first 'bra'
    if searchpos(a:tail, 'cn', a:stopline.bottom) == a:cursorpos
      let brapos = searchpairpos(a:bra, '', a:ket, 'b', '', a:stopline.top)
    endif
    let brapos = searchpairpos(a:bra, '', a:ket, 'b', '', a:stopline.top)
  elseif a:kind[0] ==# 'i'
    let head_start = searchpos(a:head, 'bc', a:stopline.top)
    let head_end   = searchpos(a:head, 'ce', a:stopline.bottom)
    call cursor(a:cursorpos)
    let tail_start = searchpos(a:tail, 'bc', a:stopline.top)
    let tail_end   = searchpos(a:tail, 'ce', a:stopline.bottom)

    " check the initial position
    if s:is_in_the_range(a:cursorpos, head_start, head_end)
      " cursor is on a header
      call cursor(head_end)
    elseif s:is_in_the_range(a:cursorpos, tail_start, tail_end)
      " cursor is on a footer
      call cursor(tail_start)
      if tail_start[1] == 1
        normal! k$
      else
        normal! h
      endif
    else
      " cursor is in between a bra and a ket
      call cursor(a:cursorpos)
    endif

    " move to the corresponded 'bra'
    let brapos = searchpairpos(a:bra, '', a:ket, 'bc', '', a:stopline.top)
  endif
  return brapos
endfunction
"}}}
function! s:elect(kind, count, candidates) abort "{{{
  if a:candidates == [] || len(a:candidates) < a:count
    return {}
  endif
  call sort(a:candidates, 's:compare')
  let elected = a:candidates[a:count - 1]
  return elected
endfunction
"}}}
function! s:select(mode, range) abort  "{{{
  if a:range == {}
    if a:mode ==# 'x'
      normal! gv
    endif
    return
  endif

  execute "normal! " . a:range.type
  call cursor(a:range.head)
  normal! o
  call cursor(a:range.tail)
  if &selection ==# 'exclusive'
    normal! l
  endif
endfunction
"}}}
function! s:is_syntax_ok(candidate, is_string_at_bra) abort "{{{
  return !a:is_string_at_bra || s:is_continuous_syntax(a:candidate.bra, a:candidate.ket)
endfunction
"}}}
function! s:is_wide_enough(candidate, kind, mode) abort "{{{
  if a:mode !=# 'x'
    let wider_than_selection = 1
  else
    let visualhead = getpos("'<")[1:2]
    let visualtail = getpos("'>")[1:2]
    let wider_than_selection =
      \    (s:is_ahead(visualhead, a:candidate.head) && s:is_equal_or_ahead(a:candidate.tail, visualtail))
      \ || (s:is_equal_or_ahead(visualhead, a:candidate.head) && s:is_ahead(a:candidate.tail, visualtail))
  endif
  if a:kind[1] ==# 'p' && s:is_equal_or_next(a:candidate.bra, a:candidate.ket)
    let is_empty_region = 1
  else
    let is_empty_region = 0
  endif
  return wider_than_selection && !is_empty_region
endfunction
"}}}
function! s:is_ahead(p1, p2) abort "{{{
  return (a:p1[0] > a:p2[0]) || (a:p1[0] == a:p2[0] && a:p1[1] > a:p2[1])
endfunction
"}}}
function! s:is_equal_or_ahead(p1, p2) abort "{{{
  return (a:p1[0] > a:p2[0]) || (a:p1[0] == a:p2[0] && a:p1[1] >= a:p2[1])
endfunction
"}}}
function! s:is_equal_or_next(p1, p2) abort "{{{
  return a:p1 == a:p2 || (a:p1[0] == a:p2[0] && a:p1[1]+1 == a:p2[1]-1)
endfunction
"}}}
function! s:is_in_the_range(pos, head, tail) abort  "{{{
  return (a:pos != s:null_pos) && (a:head != s:null_pos) && (a:tail != s:null_pos)
    \  && ((a:pos[0] > a:head[0]) || ((a:pos[0] == a:head[0]) && (a:pos[1] >= a:head[1])))
    \  && ((a:pos[0] < a:tail[0]) || ((a:pos[0] == a:tail[0]) && (a:pos[1] <= a:tail[1])))
endfunction
"}}}
function! s:is_string_literal(pos) abort  "{{{
  return match(map(synstack(a:pos[0], a:pos[1]), 'synIDattr(synIDtrans(v:val), "name")'), '\%(String\|Constant\)') > -1
endfunction
"}}}
function! s:is_continuous_syntax(brapos, ketpos) abort  "{{{
  let start_col = a:brapos[1]
  for lnum in range(a:brapos[0], a:ketpos[0])
    if lnum == a:ketpos[0]
      let end_col= a:ketpos[1]
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
function! s:get_parameter_region(candidate) abort "{{{
  let whichwrap  = &whichwrap
  let &whichwrap = 'h,l'
  let [visualhead, visualtail] = [getpos("'<"), getpos("'>")]
  try
    normal! v
    call cursor(a:candidate.bra)
    call search(a:candidate.pattern.bra, 'ce', a:candidate.ket[0])
    normal! l
    let head = getpos('.')[1:2]
    normal! o
    call cursor(a:candidate.ket)
    normal! h
    let tail = getpos('.')[1:2]
    execute "normal! \<Esc>"
  finally
    let &whichwrap = whichwrap
    call setpos("'<", visualhead)
    call setpos("'>", visualtail)
  endtry
  return [head, tail]
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
  if a:i1.len < a:i2.len
    return -1
  elseif a:i1.len > a:i2.len
    return 1
  else
    return a:i2.rank - a:i1.rank
  endif
endfunction
"}}}

" utilities
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
function! textobj#functioncall#addlist(rulelist, ...) abort "{{{
  let filetype = a:0 > 0 ? a:1 : s:filetypekey()
  call s:create_key(filetype)
  let filter = 'v:val.bra !=# "" && v:val.ket !=# ""'
  let g:textobj_functioncall_patterns[filetype] += filter(deepcopy(a:rulelist), filter)
endfunction
"}}}
function! textobj#functioncall#setlist(rulelist, ...) abort "{{{
  let filetype = a:0 > 0 ? a:1 : s:filetypekey()
  call textobj#functioncall#clear(filetype)
  call textobj#functioncall#addlist(a:rulelist, filetype)
endfunction
"}}}
function! s:filetypekey() abort "{{{
  return &filetype !=# '' ? &filetype : '_'
endfunction
"}}}
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

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set foldmethod=marker:
" vim:set commentstring="%s:
