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

| Key | Map |   |
|-----|-----|---|
| `<Space>` | `:MovealongSyntaxInline w<CR>` | Move to the next useful word.
| `<S-Space>` | `:MovealongSyntaxInline b<CR>` | Move to the previous useful word.
| `<Tab>` | `:MovealongSyntax zoj^<CR>` | Move to the next useful line.
| `<S-Tab>` | `:MovealongSyntax zok^<CR>` | Move to the previous useful line.

| Key | Map |
|-----|-----|
| `<C-Tab>` | `<expr> ":MovealongExpression zoj^ indent('.')==" . indent('.') . "<CR>"`
|           | Move to the next line with the same indent.
| `<C-S-Tab>` | `<expr> ":MovealongExpression zok^ indent('.')==" . indent('.') . "<CR>"`
|             |Move to the previous line with the same indent.

## Customization

[`:help movealong`](http://vim-doc.heroku.com/view?https://raw.github.com/toupeira/vim-movealong/master/doc/movealong.txt)

Note that you can pass any sequence of normal mode commands as motions, so the
possibilities are endless.  
Let me know if you come up with any interesting commands!
