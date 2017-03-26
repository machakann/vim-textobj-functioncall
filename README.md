vim-textobj-functioncall
========================

[![Build status](https://ci.appveyor.com/api/projects/status/7fk1871r0a8bmb5h?svg=true)](https://ci.appveyor.com/project/machakann/vim-textobj-functioncall)
[![Build Status](https://travis-ci.org/machakann/vim-textobj-functioncall.svg?branch=master)](https://travis-ci.org/machakann/vim-textobj-functioncall)

The vim textobject plugin to treat function-call regions.

Default mappings are assigned to `if` and `af`.

* `if` and `af`, both of them select a region like `func(argument)`.
* `if` and `af` behave differently when a function takes another function as its argument.
* `if` selects the most inner function under the cursor.
* `af` selects the first function including the cursor position by its parenthesis. However if any candidate would be found, it falls back to `if`.


```vim
             #              : cursor position
call func1(func2(argument))

           |<-----if---->|
call func1(func2(argument))
     |<--------af-------->|
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

This textobject could select following patterns.
* `func(argument)`
* `array[index]`

---
