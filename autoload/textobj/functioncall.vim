" textobj-functioncall
" Is there any better idea about the name?

" 'if' and 'af' behave differently when the cursor is on a string literal.
" 'if' can also recognize function calls inside the string literal.
" 'af' always ignore the string literal region.
" 'if' might not be always correct...

"                                   #              : cursor position
" call map(['1', '3', '2'], 's:sugoi_func(v:val)')
"
"                            |<-------if------>|
" call map(['1', '3', '2'], 's:sugoi_func(v:val)')
"      |<------------------af------------------->|

" TODO: The paired bra-ket search engine in string literal.
" TODO: Embedded comment should be ignored

let s:save_cpo = &cpo
set cpo&vim

let s:type_list = type([])
let s:type_dict = type({})

" default patterns
let s:functioncall_patterns = {}
let s:functioncall_patterns['_'] = [
      \ {
      \ 'header' : '\<\h\k*',
      \ 'footer' : '',
      \ 'bra'    : '(',
      \ 'ket'    : ')',
      \ },
      \ {
      \ 'header' : '\<\h\k*',
      \ 'footer' : '',
      \ 'bra'    : '\[',
      \ 'ket'    : '\]',
      \ },
      \ {
      \ 'header' : '\<\h\k*',
      \ 'footer' : '',
      \ 'bra'    : '{',
      \ 'ket'    : '}',
      \ },
      \ ]

let s:functioncall_patterns['vim'] = [
      \ {
      \ 'header' : '\<\%(s:\)\?\k*',
      \ 'footer' : '',
      \ 'bra'    : '(',
      \ 'ket'    : ')',
      \ },
      \ {
      \ 'header' : '\%(^\|[^:]\)\zs\<\%([abglstvw]:\)\?\h\k*',
      \ 'footer' : '',
      \ 'bra'    : '\[',
      \ 'ket'    : '\]',
      \ },
      \ ]

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

  " user settings
  let opt_no_default_patterns     = s:user_conf(    'no_default_patterns',  0)
  let opt_search_range_limitation = s:user_conf('search_range_limitation', 30)

  " pattern-assignment
  let pattern_list = s:resolve_patterns(opt_no_default_patterns)

  " search range limitation
  let fileend = line('$')
  if opt_search_range_limitation < 0
    let upper_line = 1
    let lower_line = fileend
  else
    let upper_line = orig_pos[0] - opt_search_range_limitation
    let upper_line = upper_line < 1 ? 1 : upper_line
    let lower_line = orig_pos[0] + opt_search_range_limitation
    let lower_line = lower_line > fileend ? fileend : lower_line
  endif

  let rank       = 0
  let candidates = []
  for pattern in pattern_list
    let rank += 1
    let [header, bra, ket, footer] = pattern

    let loop = 0
    let flag = 'bcW'
    let head = header . bra
    let tail = ket . footer
    while loop < l:count
      if flag ==# 'bcW'
        let head_start = searchpos(head, 'bcW', upper_line)
        let head_end   = searchpos(head, 'ceW', lower_line)
        call cursor(orig_pos)
        let tail_start = searchpos(tail, 'bcW', upper_line)
        let tail_end   = searchpos(tail, 'ceW', lower_line)
"         PP! [orig_pos, head, head_start, head_end, tail, tail_start, tail_end]
"         PP! [(tail_start != [0, 0]), (tail_end != [0, 0]), ((orig_pos[0] > tail_start[0]) || ((orig_pos[0] == tail_start[0]) && (orig_pos[1] >= tail_start[1]))), (((orig_pos[0] == tail_end[0]) || (orig_pos[1] <= tail_end[1])) && (orig_pos[0] < tail_end[0]))]

        " start searching
        " check the initial position
        let bra_pos_list = []
        if (head_start != [0, 0])
        \  && (head_end != [0, 0])
        \  && ((orig_pos[0] > head_start[0]) || ((orig_pos[0] == head_start[0]) && (orig_pos[1] >= head_start[1])))
        \  && (((orig_pos[0] == head_end[0]) && (orig_pos[1] <= head_end[1])) || (orig_pos[0] < head_end[0]))

"           PP! [1, pattern]
          " cursor is on a header
          call cursor(head_end)
        elseif (tail_start != [0, 0])
        \  && (tail_end != [0, 0])
        \  && ((orig_pos[0] > tail_start[0]) || ((orig_pos[0] == tail_start[0]) && (orig_pos[1] >= tail_start[1])))
        \  && (((orig_pos[0] == tail_end[0]) && (orig_pos[1] <= tail_end[1])) || (orig_pos[0] < tail_end[0]))
        \  && !s:is_string_literal(judge_syn, tail_end)

"           PP! [2, pattern]
          " cursor is on a footer
          call cursor(tail_start)
          if tail_start[1] != 1
            normal! h
          endif
        else
"           PP! [3, pattern]
          call cursor(orig_pos)
        endif
      endif

      " move to the corresponded 'bra'
      let hoge = [line('.'), col('.'), bra, ket, flag]
      let bra_pos = searchpairpos(bra, '', ket, flag, 's:is_string_literal(judge_syn, [line("."), col(".")])', upper_line)
"       PP! [hoge, bra_pos]

      if bra_pos == [0, 0]
        " go to the next pattern
"         PP! 'cannot find bra_pos, go_to_next_pattern'
        break
      endif

      let flag = 'bW'

      if !s:is_string_literal(judge_syn, bra_pos)
        " 'bra' should accompany with 'header'
        if searchpos(head, 'bcenW', upper_line) == bra_pos
          let head_pos = searchpos(head, 'bcnW', upper_line)
"           PP! ['head_pos', head_pos]

          " Start searching for the paired tail pattern.
          " update the syntax information of head
          let judge_syn = (!s:is_string_literal(((a:mode == 'i') ? 1 : 0), head_pos))

          let go_to_next_pattern = 0
          while 1
            " search for the paired 'ket'
            let ket_pos = searchpairpos(bra, '', ket, 'W', 's:is_string_literal(judge_syn, [line("."), col(".")])', lower_line)
            if ket_pos == [0, 0]
              " cannot found
"               PP! 'cannot find ket_pos, go_to_next_pattern'
              let go_to_next_pattern = 1
              break
            endif

            let tail_pos = searchpos(tail, 'ceW', lower_line)
"             PP! ['head_pos', head_pos, 'tail_pos', tail_pos]
            if tail_pos == [0, 0]
              let go_to_next_pattern = 1
              break
            elseif !s:is_string_literal(judge_syn, tail_pos) && (searchpos(tail, 'bcn', upper_line) == ket_pos)
              " found the corresponded tail
"               PP! ['successfully found!', 'head_pos', head_pos, 'tail_pos', tail_pos]
              let candidates += [[head_pos, tail_pos, rank]]
              let loop += 1
              break
            else
              " The footer condition is not matched.
              call cursor(ket_pos)
              break
            endif
          endwhile

          if go_to_next_pattern
            break
          else
            call cursor(bra_pos)
          endif
        endif
      endif
    endwhile

    call cursor(orig_pos)
  endfor

  if candidates == []
    return 0
  else
    let line_numbers = map(copy(candidates), 'v:val[0][0]') + map(copy(candidates), 'v:val[1][0]')
    let top_line     = min(line_numbers)
    let bottom_line  = max(line_numbers)

    let sorted_candidates = s:sort_candidates(candidates, top_line, bottom_line)
"     PP! sorted_candidates
    if len(sorted_candidates) > l:count - 1
      let [head_pos, tail_pos, dummy1, dummy2] = sorted_candidates[l:count - 1]
    else
      return 0
    endif

    return ['v', [0] + head_pos + [0], [0] + tail_pos + [0]]
  endif
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
function! s:user_conf(name, default)    "{{{
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
function! s:resolve_patterns(opt_no_default_patterns)  "{{{
  if a:opt_no_default_patterns
    let patterns_dict = get(g:, 'textobj_functioncall_patterns', {})
    let filetype      = has_key(patterns_dict, &filetype) ? &filetype : '_'
    let patterns      = get(patterns_dict, filetype, {})
  else
    let user_patterns = get(g:, 'textobj_functioncall_patterns', {})
    let has_filetype_key_default = has_key(s:functioncall_patterns, &filetype)
    let has_filetype_key_user    = has_key(user_patterns, &filetype)

    if has_filetype_key_default && has_filetype_key_user
      let user_filetype_patterns    = user_patterns[&filetype]
      let default_filetype_patterns = s:functioncall_patterns[&filetype]

      if (type(user_filetype_patterns) == s:type_dict) && (type(default_filetype_patterns) == s:type_dict)
        let patterns = [user_filetype_patterns] + [default_filetype_patterns]
      elseif (type(user_filetype_patterns) == s:type_dict)
        let patterns = [user_filetype_patterns] + default_filetype_patterns
      elseif (type(default_filetype_patterns) == s:type_dict)
        let patterns = user_filetype_patterns + [default_filetype_patterns]
      else
        let patterns = user_filetype_patterns + default_filetype_patterns
      endif
    elseif has_filetype_key_user
      let patterns = user_patterns[&filetype]
    elseif has_filetype_key_default
      let patterns = s:functioncall_patterns[&filetype]
    else
      let user_filetype_patterns    = get(user_patterns, '_', {})
      let default_filetype_patterns = s:functioncall_patterns['_']

      if (type(user_filetype_patterns) == s:type_dict) && (type(default_filetype_patterns) == s:type_dict)
        let patterns = [user_filetype_patterns] + [default_filetype_patterns]
      elseif (type(user_filetype_patterns) == s:type_dict)
        let patterns = [user_filetype_patterns] + default_filetype_patterns
      elseif (type(default_filetype_patterns) == s:type_dict)
        let patterns = user_filetype_patterns + [default_filetype_patterns]
      else
        let patterns = user_filetype_patterns + default_filetype_patterns
      endif
    endif
  endif

  if (type(patterns) == s:type_dict) && (patterns != {})
    return [[patterns['header'], patterns['bra'], patterns['ket'], patterns['footer']]]
  elseif type(patterns) == s:type_list && (patterns != [])
    let pattern_list = []
    for pattern in patterns
      let pattern_list += [[pattern['header'], pattern['bra'], pattern['ket'], pattern['footer']]]
    endfor

    return pattern_list
  else
    return []
  endif
endfunction
"}}}
function! s:sort_candidates(candidates, top_line, bottom_line)  "{{{
  let length_list = map(getline(a:top_line, a:bottom_line), 'len(v:val) + 1')

  let idx = 0
  let accummed_length = 0
  let accummed_list   = [0]
  for length in length_list[1:]
    let accummed_length  = accummed_length + length_list[idx]
    let accummed_list   += [accummed_length]
    let idx += 1
  endfor

  " candidates == [[head_pos], [tail_pos], rank, distance]
  let candidates = map(copy(a:candidates), '[v:val[0], v:val[1], v:val[2], ((accummed_list[v:val[1][0] - a:top_line] - v:val[0][1] + 1) + v:val[1][1])]')

  return sort(candidates, 's:compare')
endfunction
"}}}
function! s:compare(i1, i2) "{{{
  if a:i1[3] < a:i2[3]
    return -1
  elseif a:i1[3] > a:i2[3]
    return 1
  else
    return a:i2[2] - a:i1[2]
  endif
endfunction
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set foldmethod=marker:
" vim:set commentstring="%s:
