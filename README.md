movealong.vim
=============

This plugin gives you commands to repeat a motion until either a specific
syntax group is encountered, or an arbitrary expression returns true.
It also skips over blank lines, punctuation and other syntax noise.

The provided default keymaps use Tab / Shift+Tab to move around lines,
and Space / Shift+Space to move around words. Since this is pretty intrusive
these mappings are disabled by default, enable them by putting the following
into your .vimrc:

```vim
let g:movealong_default_keys = 1
```

The following keys will be mapped in normal mode:

```vim
  " Space - Move to the next useful word
  noremap <silent> <Space>         :MovealongSyntaxInline w<CR>
  " Shift-Space Move to the previous useful word
  noremap <silent> <S-Space>       :MovealongSyntaxInline b<CR>

  " Tab - Move to the next useful line
  noremap <silent> <Tab>           :MovealongSyntax zoj^<CR>
  " Shift-Tab - Move to the previous useful line
  noremap <silent> <S-Tab>         :MovealongSyntax zok^<CR>

  " Ctrl-Tab - Move to the next line with the same indent
  noremap <silent><expr> <C-Tab>   ":MovealongExpression zoj^ indent('.')==" . indent('.') . "<CR>"
  
  " Ctrl-Shift-Tab - Move to the previous line with the same indent
  noremap <silent><expr> <C-S-Tab> ":MovealongExpression zok^ indent('.')==" . indent('.') . "<CR>"
```

## Customization

[`:help movealong`](http://vim-doc.heroku.com/view?https://raw.github.com/toupeira/vim-movealong/master/doc/movealong.txt)

Note that you can pass any sequence of normal mode commands as motions, so the
possibilities are endless.  
Let me know if you come up with any interesting commands!
