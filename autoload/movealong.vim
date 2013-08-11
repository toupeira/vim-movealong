" movealong.vim - Move along, nothing to see here.
" Author:       Markus Koller
" Version:      1.0
" License:      Same as Vim itself.  See :help license

" skip over any noise
function! movealong#noise()
  return movealong#syntax('w', { 'within_line' : 1, 'syntax' : [], 'skip_syntax' : g:movealong_noise_syntax })
endfunction

"  repeat a motion until encountering a given syntax type
function! movealong#syntax(movement, options)
  let l:options = extend({
    \ 'within_line'  : 0,
    \ 'syntax'       : g:movealong_syntax,
    \ 'skip_syntax'  : g:movealong_skip_syntax,
    \ 'skip_words'   : g:movealong_skip_words,
  \ }, a:options)
    
  let l:word = ''
  let l:line_text = ''
  let l:word_syntax = ''

  " add current position to jumplist
  normal m`

  while 1
    " run the motion
    silent! execute "normal " . a:movement

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
    elseif !empty(l:options['skip_words']) && index(l:options['skip_words'], l:line_text) > -1
      " skip lines that only consist of an ignored word
      continue
    endif

    let l:syn_id = synID(l:line, l:col, 1)
    let l:word_syntax = synIDattr(synIDtrans(l:syn_id), 'name')
    let l:word_syntax_orig = synIDattr(l:syn_id, 'name')

    if !empty(l:options['syntax'])
      if index(l:options['syntax'], l:word_syntax) > -1
        " stop if syntax matches
        break
      else
        " skip lines that don't match the syntax
        continue
      endif
    endif

    " skip ignored syntax types
    if !empty(l:options['skip_syntax']) && index(l:options['skip_syntax'], l:word_syntax) > -1
      if l:word_syntax == 'Comment' || l:line_text == l:word || l:options['within_line']
        continue
      endif
    endif
    
    break
  endwhile

  " skip noise
  if !l:options['within_line'] && l:line_text != l:word && index(g:movealong_noise_syntax, l:word_syntax) > -1
    return movealong#noise()
  endif
endfunction

" repeat a motion until the given expression returns true
function! movealong#expression(movement, expression, options)
  let l:options = extend({
    \ 'within_line' : 0,
  \ }, a:options)

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

  " skip noise
  if !l:options['within_line']
    return movealong#noise()
  endif
endfunction
