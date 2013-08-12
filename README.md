movealong.vim - Context-aware motion commands
=============================================

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

[Read the full documentation online](http://vim-doc.heroku.com/view?https://raw.github.com/toupeira/vim-movealong/master/doc/movealong.txt).
