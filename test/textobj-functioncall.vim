scriptencoding utf-8
let s:suite = themis#suite('textobj-functioncall')

function! s:suite.before_each() abort "{{{
  %delete
  syntax clear
  set filetype=
  unlet! g:textobj_functioncall_patterns b:textobj_functioncall_patterns
endfunction
"}}}
function! s:suite.after() abort "{{{
  call s:suite.before_each()
endfunction
"}}}

function! s:suite.basic() dict abort "{{{
  let testset = [
        \   {
        \     'buffer': ['call header(foo)'],
        \     'input': '5ly%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": 'header(foo)',
        \       "\<Plug>(textobj-functioncall-a)": 'header(foo)',
        \       "\<Plug>(textobj-functioncall-innerparen-i)": 'foo',
        \       "\<Plug>(textobj-functioncall-innerparen-a)": 'foo',
        \     },
        \   },
        \
        \   {
        \     'buffer': ['call header(foo)'],
        \     'input': '7ly%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": 'header(foo)',
        \       "\<Plug>(textobj-functioncall-a)": 'header(foo)',
        \       "\<Plug>(textobj-functioncall-innerparen-i)": 'foo',
        \       "\<Plug>(textobj-functioncall-innerparen-a)": 'foo',
        \     },
        \   },
        \
        \   {
        \     'buffer': ['call header(foo)'],
        \     'input': '10ly%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": 'header(foo)',
        \       "\<Plug>(textobj-functioncall-a)": 'header(foo)',
        \       "\<Plug>(textobj-functioncall-innerparen-i)": 'foo',
        \       "\<Plug>(textobj-functioncall-innerparen-a)": 'foo',
        \     },
        \   },
        \
        \   {
        \     'buffer': ['call header(foo)'],
        \     'input': '11ly%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": 'header(foo)',
        \       "\<Plug>(textobj-functioncall-a)": 'header(foo)',
        \       "\<Plug>(textobj-functioncall-innerparen-i)": 'foo',
        \       "\<Plug>(textobj-functioncall-innerparen-a)": 'foo',
        \     },
        \   },
        \
        \   {
        \     'buffer': ['call header(foo)'],
        \     'input': '13ly%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": 'header(foo)',
        \       "\<Plug>(textobj-functioncall-a)": 'header(foo)',
        \       "\<Plug>(textobj-functioncall-innerparen-i)": 'foo',
        \       "\<Plug>(textobj-functioncall-innerparen-a)": 'foo',
        \     },
        \   },
        \
        \   {
        \     'buffer': ['call header(foo)'],
        \     'input': '15ly%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": 'header(foo)',
        \       "\<Plug>(textobj-functioncall-a)": 'header(foo)',
        \       "\<Plug>(textobj-functioncall-innerparen-i)": 'foo',
        \       "\<Plug>(textobj-functioncall-innerparen-a)": 'foo',
        \     },
        \   },
        \ ]
  call s:trytestset(testset)

  let g:textobj_functioncall_patterns = [{'header': '', 'bra': '(', 'ket': ')', 'footer': 'footer'}]
  let testset = [
        \   {
        \     'buffer': ['call (foo)footer'],
        \     'input':  '5ly%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": '(foo)footer',
        \       "\<Plug>(textobj-functioncall-a)": '(foo)footer',
        \       "\<Plug>(textobj-functioncall-innerparen-i)": 'foo',
        \       "\<Plug>(textobj-functioncall-innerparen-a)": 'foo',
        \     },
        \   },
        \
        \   {
        \     'buffer': ['call (foo)footer'],
        \     'input':  '7ly%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": '(foo)footer',
        \       "\<Plug>(textobj-functioncall-a)": '(foo)footer',
        \       "\<Plug>(textobj-functioncall-innerparen-i)": 'foo',
        \       "\<Plug>(textobj-functioncall-innerparen-a)": 'foo',
        \     },
        \   },
        \
        \   {
        \     'buffer': ['call (foo)footer'],
        \     'input':  '9ly%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": '(foo)footer',
        \       "\<Plug>(textobj-functioncall-a)": '(foo)footer',
        \       "\<Plug>(textobj-functioncall-innerparen-i)": 'foo',
        \       "\<Plug>(textobj-functioncall-innerparen-a)": 'foo',
        \     },
        \   },
        \
        \   {
        \     'buffer': ['call (foo)footer'],
        \     'input': '10ly%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": '(foo)footer',
        \       "\<Plug>(textobj-functioncall-a)": '(foo)footer',
        \       "\<Plug>(textobj-functioncall-innerparen-i)": 'foo',
        \       "\<Plug>(textobj-functioncall-innerparen-a)": 'foo',
        \     },
        \   },
        \
        \   {
        \     'buffer': ['call (foo)footer'],
        \     'input': '12ly%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": '(foo)footer',
        \       "\<Plug>(textobj-functioncall-a)": '(foo)footer',
        \       "\<Plug>(textobj-functioncall-innerparen-i)": 'foo',
        \       "\<Plug>(textobj-functioncall-innerparen-a)": 'foo',
        \     },
        \   },
        \
        \   {
        \     'buffer': ['call (foo)footer'],
        \     'input': '15ly%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": '(foo)footer',
        \       "\<Plug>(textobj-functioncall-a)": '(foo)footer',
        \       "\<Plug>(textobj-functioncall-innerparen-i)": 'foo',
        \       "\<Plug>(textobj-functioncall-innerparen-a)": 'foo',
        \     },
        \   },
        \ ]
  call s:trytestset(testset)
endfunction
"}}}
function! s:suite.cursorpos() dict abort "{{{
  let testset = [
        \   {
        \     'buffer': ['call foo(foo, bar(bar))'],
        \     'input': '13ly%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": 'foo(foo, bar(bar))',
        \       "\<Plug>(textobj-functioncall-a)": 'foo(foo, bar(bar))',
        \       "\<Plug>(textobj-functioncall-innerparen-i)": 'foo, bar(bar)',
        \       "\<Plug>(textobj-functioncall-innerparen-a)": 'foo, bar(bar)',
        \     },
        \   },
        \
        \   {
        \     'buffer': ['call foo(foo, bar(bar))'],
        \     'input': '14ly%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": 'bar(bar)',
        \       "\<Plug>(textobj-functioncall-a)": 'foo(foo, bar(bar))',
        \       "\<Plug>(textobj-functioncall-innerparen-i)": 'bar',
        \       "\<Plug>(textobj-functioncall-innerparen-a)": 'foo, bar(bar)',
        \     },
        \   },
        \
        \   {
        \     'buffer': ['call foo(foo, bar(bar))'],
        \     'input': '17ly%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": 'bar(bar)',
        \       "\<Plug>(textobj-functioncall-a)": 'foo(foo, bar(bar))',
        \       "\<Plug>(textobj-functioncall-innerparen-i)": 'bar',
        \       "\<Plug>(textobj-functioncall-innerparen-a)": 'foo, bar(bar)',
        \     },
        \   },
        \
        \   {
        \     'buffer': ['call foo(foo, bar(bar))'],
        \     'input': '21ly%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": 'bar(bar)',
        \       "\<Plug>(textobj-functioncall-a)": 'foo(foo, bar(bar))',
        \       "\<Plug>(textobj-functioncall-innerparen-i)": 'bar',
        \       "\<Plug>(textobj-functioncall-innerparen-a)": 'foo, bar(bar)',
        \     },
        \   },
        \
        \   {
        \     'buffer': ['call foo(foo, bar(bar))'],
        \     'input': '22ly%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": 'foo(foo, bar(bar))',
        \       "\<Plug>(textobj-functioncall-a)": 'foo(foo, bar(bar))',
        \       "\<Plug>(textobj-functioncall-innerparen-i)": 'foo, bar(bar)',
        \       "\<Plug>(textobj-functioncall-innerparen-a)": 'foo, bar(bar)',
        \     },
        \   },
        \ ]
  call s:trytestset(testset)
endfunction
"}}}
function! s:suite.count() dict abort "{{{
  " count
  let testset = [
        \   {
        \     'buffer': ['call foo(foo, bar(bar, baz(baz)))'],
        \     'input': '28ly1%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": 'baz(baz)',
        \       "\<Plug>(textobj-functioncall-a)": 'baz(baz)',
        \       "\<Plug>(textobj-functioncall-innerparen-i)": 'baz',
        \       "\<Plug>(textobj-functioncall-innerparen-a)": 'baz',
        \     },
        \   },
        \
        \   {
        \     'buffer': ['call foo(foo, bar(bar, baz(baz)))'],
        \     'input': '28ly2%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": 'bar(bar, baz(baz))',
        \       "\<Plug>(textobj-functioncall-a)": 'bar(bar, baz(baz))',
        \       "\<Plug>(textobj-functioncall-innerparen-i)": 'bar, baz(baz)',
        \       "\<Plug>(textobj-functioncall-innerparen-a)": 'bar, baz(baz)',
        \     },
        \   },
        \
        \   {
        \     'buffer': ['call foo(foo, bar(bar, baz(baz)))'],
        \     'input': '28ly3%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": 'foo(foo, bar(bar, baz(baz)))',
        \       "\<Plug>(textobj-functioncall-a)": 'foo(foo, bar(bar, baz(baz)))',
        \       "\<Plug>(textobj-functioncall-innerparen-i)": 'foo, bar(bar, baz(baz))',
        \       "\<Plug>(textobj-functioncall-innerparen-a)": 'foo, bar(bar, baz(baz))',
        \     },
        \   },
        \
        \   {
        \     'buffer': ['call foo(foo, bar(bar, baz(baz)))'],
        \     'input': '28ly4%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": '',
        \       "\<Plug>(textobj-functioncall-a)": '',
        \       "\<Plug>(textobj-functioncall-innerparen-i)": '',
        \       "\<Plug>(textobj-functioncall-innerparen-a)": '',
        \     },
        \   },
        \ ]
  call s:trytestset(testset)
endfunction
"}}}
function! s:suite.multiplepatterns() dict abort "{{{
  let testset = [
        \   {
        \     'buffer': ['call foo(bar[baz])'],
        \     'input':  '5ly%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": 'foo(bar[baz])',
        \       "\<Plug>(textobj-functioncall-a)": 'foo(bar[baz])',
        \       "\<Plug>(textobj-functioncall-innerparen-i)": 'bar[baz]',
        \       "\<Plug>(textobj-functioncall-innerparen-a)": 'bar[baz]',
        \     },
        \   },
        \
        \   {
        \     'buffer': ['call foo(bar[baz])'],
        \     'input': '10ly%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": 'bar[baz]',
        \       "\<Plug>(textobj-functioncall-a)": 'foo(bar[baz])',
        \       "\<Plug>(textobj-functioncall-innerparen-i)": 'baz',
        \       "\<Plug>(textobj-functioncall-innerparen-a)": 'bar[baz]',
        \     },
        \   },
        \
        \   {
        \     'buffer': ['call foo(bar[baz])'],
        \     'input': '14ly%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": 'bar[baz]',
        \       "\<Plug>(textobj-functioncall-a)": 'bar[baz]',
        \       "\<Plug>(textobj-functioncall-innerparen-i)": 'baz',
        \       "\<Plug>(textobj-functioncall-innerparen-a)": 'baz',
        \     },
        \   },
        \ ]
  call s:trytestset(testset)
endfunction
"}}}
function! s:suite.filetype() dict abort "{{{
  let testset = [
        \   {
        \     'buffer': ['call s:foo(a:bar[baz])'],
        \     'input':  '5ly%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": 's:foo(a:bar[baz])',
        \       "\<Plug>(textobj-functioncall-a)": 's:foo(a:bar[baz])',
        \       "\<Plug>(textobj-functioncall-innerparen-i)": 'a:bar[baz]',
        \       "\<Plug>(textobj-functioncall-innerparen-a)": 'a:bar[baz]',
        \     },
        \   },
        \
        \   {
        \     'buffer': ['call s:foo(a:bar[baz])'],
        \     'input': '11ly%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": 'a:bar[baz]',
        \       "\<Plug>(textobj-functioncall-a)": 's:foo(a:bar[baz])',
        \       "\<Plug>(textobj-functioncall-innerparen-i)": 'baz',
        \       "\<Plug>(textobj-functioncall-innerparen-a)": 'a:bar[baz]',
        \     },
        \   },
        \
        \   {
        \     'buffer': ['call s:foo(a:bar[baz])'],
        \     'input': '18ly%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": 'a:bar[baz]',
        \       "\<Plug>(textobj-functioncall-a)": 'a:bar[baz]',
        \       "\<Plug>(textobj-functioncall-innerparen-i)": 'baz',
        \       "\<Plug>(textobj-functioncall-innerparen-a)": 'baz',
        \     },
        \   },
        \ ]
  runtime ftplugin/vim/textobj_functioncall.vim
  call s:trytestset(testset)
endfunction
"}}}
function! s:suite.multilines() dict abort "{{{
  let testset = [
        \   {
        \     'buffer': ['call foo(', 'bar', ')'],
        \     'input': '5ly%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": "foo(\nbar\n)",
        \       "\<Plug>(textobj-functioncall-a)": "foo(\nbar\n)",
        \       "\<Plug>(textobj-functioncall-innerparen-i)": "\nbar\n",
        \       "\<Plug>(textobj-functioncall-innerparen-a)": "\nbar\n",
        \     },
        \   },
        \
        \   {
        \     'buffer': ['call foo(', 'bar', ')'],
        \     'input': 'jly%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": "foo(\nbar\n)",
        \       "\<Plug>(textobj-functioncall-a)": "foo(\nbar\n)",
        \       "\<Plug>(textobj-functioncall-innerparen-i)": "\nbar\n",
        \       "\<Plug>(textobj-functioncall-innerparen-a)": "\nbar\n",
        \     },
        \   },
        \
        \   {
        \     'buffer': ['call foo(', 'bar', ')'],
        \     'input': '2jy%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": "foo(\nbar\n)",
        \       "\<Plug>(textobj-functioncall-a)": "foo(\nbar\n)",
        \       "\<Plug>(textobj-functioncall-innerparen-i)": "\nbar\n",
        \       "\<Plug>(textobj-functioncall-innerparen-a)": "\nbar\n",
        \     },
        \   },
        \
        \   {
        \     'buffer': ['call foo(', '  bar', '  )'],
        \     'input': '5ly%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": "foo(\n  bar\n  )",
        \       "\<Plug>(textobj-functioncall-a)": "foo(\n  bar\n  )",
        \       "\<Plug>(textobj-functioncall-innerparen-i)": "\n  bar\n  ",
        \       "\<Plug>(textobj-functioncall-innerparen-a)": "\n  bar\n  ",
        \     },
        \   },
        \
        \   {
        \     'buffer': ['call foo(', '  bar', '  )'],
        \     'input': 'j2ly%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": "foo(\n  bar\n  )",
        \       "\<Plug>(textobj-functioncall-a)": "foo(\n  bar\n  )",
        \       "\<Plug>(textobj-functioncall-innerparen-i)": "\n  bar\n  ",
        \       "\<Plug>(textobj-functioncall-innerparen-a)": "\n  bar\n  ",
        \     },
        \   },
        \
        \   {
        \     'buffer': ['call foo(', '  bar', '  )'],
        \     'input': '2j2ly%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": "foo(\n  bar\n  )",
        \       "\<Plug>(textobj-functioncall-a)": "foo(\n  bar\n  )",
        \       "\<Plug>(textobj-functioncall-innerparen-i)": "\n  bar\n  ",
        \       "\<Plug>(textobj-functioncall-innerparen-a)": "\n  bar\n  ",
        \     },
        \   },
        \ ]
  call s:trytestset(testset)
endfunction
"}}}
function! s:suite.nastycases() dict abort "{{{
  let testset = [
        \   {
        \     'buffer': ["call foo(foo, ')')"],
        \     'input':  '11ly%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": "foo(foo, ')')",
        \       "\<Plug>(textobj-functioncall-a)": "foo(foo, ')')",
        \       "\<Plug>(textobj-functioncall-innerparen-i)": "foo, ')'",
        \       "\<Plug>(textobj-functioncall-innerparen-a)": "foo, ')'",
        \     },
        \   },
        \
        \   {
        \     'buffer': ["call foo(foo, ')')"],
        \     'input': '15ly%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": "foo(foo, ')')",
        \       "\<Plug>(textobj-functioncall-a)": "foo(foo, ')')",
        \       "\<Plug>(textobj-functioncall-innerparen-i)": "foo, ')'",
        \       "\<Plug>(textobj-functioncall-innerparen-a)": "foo, ')'",
        \     },
        \   },
        \
        \   {
        \     'buffer': ["call foo('(', foo)"],
        \     'input': '14ly%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": "foo('(', foo)",
        \       "\<Plug>(textobj-functioncall-a)": "foo('(', foo)",
        \       "\<Plug>(textobj-functioncall-innerparen-i)": "'(', foo",
        \       "\<Plug>(textobj-functioncall-innerparen-a)": "'(', foo",
        \     },
        \   },
        \
        \   {
        \     'buffer': ["call foo('(', foo)"],
        \     'input': '17ly%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": "foo('(', foo)",
        \       "\<Plug>(textobj-functioncall-a)": "foo('(', foo)",
        \       "\<Plug>(textobj-functioncall-innerparen-i)": "'(', foo",
        \       "\<Plug>(textobj-functioncall-innerparen-a)": "'(', foo",
        \     },
        \   },
        \ ]
  runtime syntax/vim.vim
  call s:trytestset(testset)
endfunction
"}}}
function! s:suite.longbraket() dict abort "{{{
  let g:textobj_functioncall_patterns = [{'header': 'foo', 'bra': '{(', 'ket': ')}', 'footer': ''}]
  let testset = [
        \   {
        \     'buffer': ['call foo{(bar)}'],
        \     'input': '5ly%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": "foo{(bar)}",
        \       "\<Plug>(textobj-functioncall-a)": "foo{(bar)}",
        \       "\<Plug>(textobj-functioncall-innerparen-i)": "bar",
        \       "\<Plug>(textobj-functioncall-innerparen-a)": "bar",
        \     },
        \   },
        \
        \   {
        \     'buffer': ['call foo{(bar)}'],
        \     'input': '8ly%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": "foo{(bar)}",
        \       "\<Plug>(textobj-functioncall-a)": "foo{(bar)}",
        \       "\<Plug>(textobj-functioncall-innerparen-i)": "bar",
        \       "\<Plug>(textobj-functioncall-innerparen-a)": "bar",
        \     },
        \   },
        \
        \   {
        \     'buffer': ['call foo{(bar)}'],
        \     'input': '11ly%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": "foo{(bar)}",
        \       "\<Plug>(textobj-functioncall-a)": "foo{(bar)}",
        \       "\<Plug>(textobj-functioncall-innerparen-i)": "bar",
        \       "\<Plug>(textobj-functioncall-innerparen-a)": "bar",
        \     },
        \   },
        \
        \   {
        \     'buffer': ['call foo{(bar)}'],
        \     'input': '14ly%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": "foo{(bar)}",
        \       "\<Plug>(textobj-functioncall-a)": "foo{(bar)}",
        \       "\<Plug>(textobj-functioncall-innerparen-i)": "bar",
        \       "\<Plug>(textobj-functioncall-innerparen-a)": "bar",
        \     },
        \   },
        \ ]
  call s:trytestset(testset)



  let g:textobj_functioncall_patterns = [{'header': '', 'bra': '{(', 'ket': ')}', 'footer': 'foo'}]
  let testset = [
        \   {
        \     'buffer': ['call {(bar)}foo'],
        \     'input': '5ly%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": "{(bar)}foo",
        \       "\<Plug>(textobj-functioncall-a)": "{(bar)}foo",
        \       "\<Plug>(textobj-functioncall-innerparen-i)": "bar",
        \       "\<Plug>(textobj-functioncall-innerparen-a)": "bar",
        \     },
        \   },
        \
        \   {
        \     'buffer': ['call {(bar)}foo'],
        \     'input': '8ly%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": "{(bar)}foo",
        \       "\<Plug>(textobj-functioncall-a)": "{(bar)}foo",
        \       "\<Plug>(textobj-functioncall-innerparen-i)": "bar",
        \       "\<Plug>(textobj-functioncall-innerparen-a)": "bar",
        \     },
        \   },
        \
        \   {
        \     'buffer': ['call {(bar)}foo'],
        \     'input': '11ly%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": "{(bar)}foo",
        \       "\<Plug>(textobj-functioncall-a)": "{(bar)}foo",
        \       "\<Plug>(textobj-functioncall-innerparen-i)": "bar",
        \       "\<Plug>(textobj-functioncall-innerparen-a)": "bar",
        \     },
        \   },
        \
        \   {
        \     'buffer': ['call {(bar)}foo'],
        \     'input': '14ly%s',
        \     'expect': {
        \       "\<Plug>(textobj-functioncall-i)": "{(bar)}foo",
        \       "\<Plug>(textobj-functioncall-a)": "{(bar)}foo",
        \       "\<Plug>(textobj-functioncall-innerparen-i)": "bar",
        \       "\<Plug>(textobj-functioncall-innerparen-a)": "bar",
        \     },
        \   },
        \ ]
  call s:trytestset(testset)
endfunction
"}}}

function! s:trytestset(testset) abort "{{{
  for test in a:testset
    call s:try(test)
  endfor
endfunction
"}}}
function! s:try(test) abort "{{{
  %delete
  let @@ = 'nul'
  call append(0, a:test.buffer)
  for [key, expect] in items(a:test.expect)
    let keyseq = printf(a:test.input, key)
    normal! gg
    execute 'normal ' . keyseq
    call g:assert.equals(@@, expect, s:message(keyseq))
  endfor
endfunction
"}}}
function! s:message(keyseq) abort "{{{
  let message = []
  let message += ['input: ' . substitute(a:keyseq, "\<Plug>", '<Plug>', 'g')]
  let message += ['buffer: ']
  let message += getline(1, '$')
  return join(message, "\n") . "\n"
endfunction
"}}}



" vim:set foldmethod=marker:
" vim:set commentstring="%s:
