vim-textobj-functioncall
========================

The vim textobject plugin to treat function-call regions.

Default mappings are assigned to `if` and `af`.

* `if` and 'af' behave differently when the cursor is on a string literal.
* `if` can also recognize function calls inside the string literal.
* `af` always ignore the string literal region.
* `if` might not be always correct...


```vim
                                  #              : cursor position
call map(['1', '3', '2'], 's:sugoi_func(v:val)')

                           |<-------if------>|
call map(['1', '3', '2'], 's:sugoi_func(v:val)')
     |<------------------af------------------->|
```

---

If you don't like to map to `if` and `af`, please define the variable named `g:textobj_functioncall_no_default_key_mappings` in your vimrc.
```vim
let g:textobj_functioncall_no_default_key_mappings = 1
```

And then map to your preferable keys.
```vim
xmap iF <Plug>(textobj-functioncall-i)
omap iF <Plug>(textobj-functioncall-i)
xmap aF <Plug>(textobj-functioncall-a)
omap aF <Plug>(textobj-functioncall-a)
```

---

お探しのものはこちらかもしれません

→あにゃログ - textobj-xbrackets.vim
http://www.sopht.jp/blog/index.php?/archives/449-textobj-xbrackets.vim.html
