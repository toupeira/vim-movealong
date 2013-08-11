" movealong.vim - Move along, nothing to see here.
" Author:       Markus Koller
" Version:      1.0
" License:      Same as Vim itself.  See :help license

" repeat a motion until the given expression returns true
function! movealong#expression(movement, expression)
  " add current position to jumplist
  normal m`

  while 1
    " run the motion
    silent! execute "normal " . a:movement

    if line('.') == line('$')
      " stop at the last line
      break
    endif

    if eval(a:expression)
      break
    endif
  endwhile
endfunction

"  repeat a motion until encountering a given syntax type
function! movealong#syntax(...)
  let l:movement    = a:1
  let l:syntax      = a:0 > 1 ? ListWrap(a:2) : g:movealong_syntax
  let l:skip_syntax = a:0 > 2 ? ListWrap(a:3) : g:movealong_skip_syntax
  let l:skip_words  = a:0 > 3 ? ListWrap(a:4) : g:movealong_skip_words
  let l:skip_noise  = a:0 > 4 ? a:5           : g:movealong_skip_noise

  let l:word = ''
  let l:line_text = ''
  let l:word_syntax = ''

  " add current position to jumplist
  normal m`

  while 1
    " run the motion
    silent! execute "normal " . l:movement

    let l:line = line('.')
    let l:col  = col('.')

    if l:line == line('$')
      " stop at the last line
      break
    endif

    let l:word = expand('<cword>')
    let l:line_text = substitute(getline('.'), ' ', '', 'g')

    if match(l:line_text, '[^ \t]') == -1
      " skip blank lines
      continue
    elseif !empty(l:skip_words) && index(l:skip_words, l:line_text) > -1
      " skip lines that only consist of an ignored word
      continue
    endif

    let l:syn_id = synID(l:line, l:col, 1)
    let l:word_syntax = synIDattr(synIDtrans(l:syn_id), 'name')
    let l:word_syntax_orig = synIDattr(l:syn_id, 'name')

    if !empty(l:syntax)
      if index(l:syntax, l:word_syntax) > -1
        " stop if syntax matches
        break
      else
        " skip lines that don't match the syntax
        continue
      endif
    endif

    " skip ignored syntax types
    if !empty(l:skip_syntax) && index(l:skip_syntax, l:word_syntax) > -1
      if l:word_syntax == 'Comment' || l:movement == 'w' || l:line_text == l:word
        continue
      endif
    endif
    
    break
  endwhile

  " skip noise
  if l:skip_noise && l:line_text != l:word && index(g:movealong_noise_syntax, l:word_syntax) > -1
    return movealong#syntax('w', [], g:movealong_noise_syntax, [], 0)
  endif
endfunction
