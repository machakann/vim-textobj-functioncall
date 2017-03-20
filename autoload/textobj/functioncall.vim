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

function! textobj#functioncall#i(mode) abort
  call s:textobj('i', a:mode)
endfunction

function! textobj#functioncall#a(mode) abort
  call s:textobj('a', a:mode)
endfunction

function! textobj#functioncall#ip(mode) abort
  call s:textobj('ip', a:mode)
endfunction

function! textobj#functioncall#ap(mode) abort
  call s:textobj('ap', a:mode)
endfunction

function! s:textobj(kind, mode) abort  "{{{
  let l:count = v:count1
  let visualmode = a:mode ==# 'x' ? visualmode() : 'v'

  " user settings
  let searchlines = s:user_conf('search_lines' , 30)
  let patternlist = s:resolve_patterns()

  let view = winsaveview()
  try
    let candidates = s:gather_candidates(a:kind, a:mode, l:count, patternlist, searchlines)
    let range = s:get_range(a:kind, l:count, candidates)
  finally
    call winrestview(view)
  endtry
  call s:select(a:mode, visualmode, range)
endfunction
"}}}
function! s:gather_candidates(kind, mode, count, patternlist, searchlines) abort  "{{{
  let cursorpos = getpos('.')[1:2]

  " searching range limitation
  if a:searchlines < 0
    let upperline = 1
    let lowerline = line('$')
  else
    let upperline = max([1, cursorpos[0] - a:searchlines])
    let lowerline = min([cursorpos[0] + a:searchlines, line('$')])
  endif

  let rank = 0
  let candidates = []
  for pattern in a:patternlist
    let rank += 1
    let candidates += s:search_pattern(pattern, a:kind, a:mode, a:count, rank, cursorpos, upperline, lowerline)
    call cursor(cursorpos)
  endfor
  return a:kind[0] ==# 'a' && candidates == []
        \ ? s:gather_candidates('i', a:mode, a:count, a:patternlist, a:searchlines)
        \ : candidates
endfunction
"}}}
function! s:search_pattern(pattern, kind, mode, count, rank, cursorpos, upperline, lowerline) abort "{{{
  let candidates = []
  let header = a:pattern.header
  let bra    = a:pattern.bra
  let ket    = a:pattern.ket
  let footer = a:pattern.footer

  let head = header . bra
  let tail = ket . footer

  let brapos = s:search_key_bra(a:kind, a:cursorpos, bra, ket, head, tail, a:upperline, a:lowerline)
  if brapos == s:null_pos | return [] | endif
  let is_string_at_bra = s:is_string_literal(brapos)

  while len(candidates) < a:count
    " 'bra' should accompany with 'header'
    if searchpos(head, 'bcen', a:upperline) == brapos
      let headpos = searchpos(head, 'bcn', a:upperline)

      " search for the paired 'ket'
      let ketpos = searchpairpos(bra, '', ket, '', 's:is_string_literal(getpos(".")[1:2]) != is_string_at_bra', a:lowerline)
      if ketpos != s:null_pos
        let tailpos = searchpos(tail, 'ce', a:lowerline)
        if tailpos == s:null_pos
          break
        elseif searchpos(tail, 'bcn', a:upperline) == ketpos
          let candidate = s:get_candidate(headpos, brapos, ketpos, tailpos, a:rank)
          if s:is_wide_enough(candidate, a:mode) && s:is_syntax_ok(candidate, is_string_at_bra)
            " found the corresponded tail
            let candidates += [candidate]
          endif
        endif
      endif
      call cursor(brapos)
    endif

    " move to the next 'bra'
    let brapos = searchpairpos(bra, '', ket, 'b', '', a:upperline)
    if brapos == s:null_pos | break | endif
    let is_string_at_bra = s:is_string_literal(brapos)
  endwhile
  return candidates
endfunction
"}}}
function! s:search_key_bra(kind, cursorpos, bra, ket, head, tail, upperline, lowerline) abort  "{{{
  let brapos = s:null_pos
  if a:kind[0] ==# 'a'
    " search for the first 'bra'
    if searchpos(a:tail, 'cn', a:lowerline) == a:cursorpos
      let brapos = searchpairpos(a:bra, '', a:ket, 'b', '', a:upperline)
    endif
    let brapos = searchpairpos(a:bra, '', a:ket, 'b', '', a:upperline)
  elseif a:kind[0] ==# 'i'
    let head_start = searchpos(a:head, 'bc', a:upperline)
    let head_end   = searchpos(a:head, 'ce', a:lowerline)
    call cursor(a:cursorpos)
    let tail_start = searchpos(a:tail, 'bc', a:upperline)
    let tail_end   = searchpos(a:tail, 'ce', a:lowerline)

    " check the initial position
    if s:is_in_the_range(a:cursorpos, head_start, head_end)
      " cursor is on a header
      call cursor(head_end)
    elseif s:is_in_the_range(a:cursorpos, tail_start, tail_end)
      " cursor is on a footer
      call cursor(tail_start)
      if tail_start[1] != 1
        normal! h
      endif
    else
      " cursor is in between a bra and a ket
      call cursor(a:cursorpos)
    endif

    " move to the corresponded 'bra'
    let brapos = searchpairpos(a:bra, '', a:ket, 'bc', '', a:upperline)
  endif
  return brapos
endfunction
"}}}
function! s:get_candidate(headpos, brapos, ketpos, tailpos, rank) abort "{{{
  return {
        \   'head': a:headpos,
        \   'bra': a:brapos,
        \   'ket': a:ketpos,
        \   'tail': a:tailpos,
        \   'rank': a:rank,
        \   'len': s:get_buf_length(a:headpos, a:tailpos)
        \ }
endfunction
"}}}
function! s:get_range(kind, count, candidates) abort "{{{
  let head = copy(s:null_pos)
  let tail = copy(s:null_pos)
  if a:candidates != []
    call sort(a:candidates, 's:compare')
    if len(a:candidates) >= a:count
      let elected = a:candidates[a:count - 1]
      if a:kind[1] ==# 'p'
        if !(elected.bra == elected.ket || (elected.bra[0] == elected.ket[0] && elected.bra[1]+1 == elected.ket[1]-1))
          let [head, tail] = s:get_narrower_region(elected.bra, elected.ket)
        endif
      else
        let head = elected.head
        let tail = elected.tail
      endif
    endif
  endif
  return [head, tail]
endfunction
"}}}
function! s:select(mode, visualmode, range) abort  "{{{
  let [head, tail] = a:range
  if head != s:null_pos && tail != s:null_pos
    execute "normal! " . a:visualmode
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
function! s:is_syntax_ok(candidate, is_string_at_bra) abort "{{{
  return !a:is_string_at_bra || s:is_continuous_syntax(a:candidate.bra, a:candidate.ket)
endfunction
"}}}
function! s:is_wide_enough(candidate, mode) abort "{{{
  if a:mode !=# 'x'
    let is_wide_enough = 1
  else
    let visualhead = getpos("'<")[1:2]
    let visualtail = getpos("'>")[1:2]
    let is_wide_enough = (s:is_ahead(visualhead, a:candidate.head) && s:is_equal_or_ahead(a:candidate.tail, visualtail))
                    \ || (s:is_equal_or_ahead(visualhead, a:candidate.head) && s:is_ahead(a:candidate.tail, visualtail))
  endif
  return is_wide_enough
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

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set foldmethod=marker:
" vim:set commentstring="%s:
