" movealong.vim - Move along, nothing to see here.
" Author:       Markus Koller
" Version:      1.0
" License:      Same as Vim itself.  See :help license

" get the syntax names for the current cursor position
function! movealong#syntax#current()
  let id       = synID(line('.'), col('.'), 1)
  let name     = synIDattr(synIDtrans(id), 'name')
  let original = synIDattr(id, 'name')

  return {
    \ 'id'       : id,
    \ 'name'     : name,
    \ 'original' : original,
  \ }
endfunction

" check if the syntax names match any of the given groups
function! movealong#syntax#match(syntax, groups)
  return (has_key(a:syntax, 'name') && index(a:groups, a:syntax['name']) > -1)
    \ || (has_key(a:syntax, 'original') && index(a:groups, a:syntax['original']) > -1)
endfunction

" skip over any syntax noise
function! movealong#syntax#noise(...)
  let options = extend({
    \ 'inline'      : 1,
    \ 'syntax'      : [],
    \ 'skip_syntax' : movealong#setting('skip_syntax_inline'),
    \ 'cross_lines' : 0,
  \ }, a:0 > 0 ? a:1 : {})

  return movealong#syntax('w', options)
endfunction
