movealong.vim
=============

This plugin gives you commands to repeat a motion until either a specific
word or syntax group is encountered, or an arbitrary expression returns true.
It also skips over blank lines, punctuation and other syntax noise.

The included default keymaps are disabled by default, you can enable them
by putting the following into your `.vimrc`:

```vim
let g:movealong_default_keys = 1
```

You can also override any of the default keys as follows: >

```vim
  let g:movealong_default_maps = {
    \ 'WordForward'  : '<Space>',
    \ 'WordBackward' : '<Backspace>',
    \ 'LineForward'  : '<Tab>',
    " ... etc.
  \ }
```

The following keys will be mapped in normal mode:

```vim
  " Space - Move to the next useful word
  noremap <silent> <Space>         :Movealong w -defaults<CR>
  " Shift-Space Move to the previous useful word
  noremap <silent> <S-Space>       :Movealong b -defaults<CR>

  " Tab - Move to the next useful line
  noremap <silent> <Tab>           :Movealong j^ -defaults<CR>
  " Shift-Tab - Move to the previous useful line
  noremap <silent> <S-Tab>         :Movealong k^ -defaults<CR>

  " <Leader>i - Move to the next line with the same indent
  noremap <silent><expr> <C-Tab>   ":Movealong j^ -expression indent('.')==" . indent('.') . "<CR>"
  
  " <Leader>I - Move to the previous line with the same indent
  noremap <silent><expr> <C-S-Tab> ":Movealong k^ -expression indent('.')==" . indent('.') . "<CR>"

  " <Leader>f - Move to the next function declaration
  nnoremap <silent> <Leader>f :Movealong j^ -defaults -syntax vimFuncKey,rubyDefine,pythonFunction,phpFCKeyword<CR>

  " <Leader>F - Move to the previous function declaration
  nnoremap <silent> <Leader>F :Movealong k^ -defaults -syntax vimFuncKey,rubyDefine,pythonFunction,phpFCKeyword<CR>
```

## Customization

See [`:help Movealong`](http://vim-doc.heroku.com/view?https://raw.github.com/toupeira/vim-movealong/master/doc/movealong.txt) for more information.

[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/toupeira/vim-movealong/trend.png)](https://bitdeli.com/free "Bitdeli Badge")
