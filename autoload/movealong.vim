" movealong.vim - Move along, nothing to see here.
" Author:       Markus Koller
" Version:      1.0
" License:      Same as Vim itself.  See :help license

" skip over any noise
function! movealong#noise(skip_syntax)
  return movealong#syntax('w', { 'inline' : 1, 'syntax' : [], 'skip_syntax' : a:skip_syntax })
endfunction

"  repeat a motion until encountering a given syntax type
function! movealong#syntax(movement, options)
  let l:options = extend({
    \ 'inline'      : 0,
    \ 'syntax'      : g:movealong_syntax,
    \ 'skip_punct'  : g:movealong_skip_punct,
    \ 'skip_words'  : g:movealong_skip_words,
  \ }, a:options)
    
  let l:options = extend(l:options, {
    \ 'skip_syntax' : l:options['inline'] ? g:movealong_skip_syntax_inline : g:movealong_skip_syntax
  \ })

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

    "let l:word = expand('<cword>')
    normal "-yiw
    let l:word = getreg('-')
    let l:line_text = substitute(getline('.'), ' ', '', 'g')

    if match(l:line_text, '[^ \t]') == -1
      " skip blank lines
      continue
    elseif l:options['skip_punct'] && match(l:options['inline'] ? l:word : l:line_text, '\v^[[:punct:]]+$') > -1
      " skip punctuation
      continue
    elseif !empty(l:options['skip_words']) && index(l:options['skip_words'], l:options['inline'] ? l:word : l:line_text) > -1
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
    "if !empty(l:options['skip_syntax']) && index(l:options['skip_syntax'], l:word_syntax) > -1
    if !empty(l:options['skip_syntax']) && index(l:options['skip_syntax'], l:word_syntax) > -1
      if l:word_syntax == 'Comment' || l:line_text == l:word || l:options['inline']
        continue
      endif
    endif
    
    break
  endwhile

  " skip noise
  if !l:options['inline'] && l:line_text != l:word && (index(l:options['skip_syntax'], l:word_syntax) > -1 || match(l:line_text, '\v^\s*[[:punct:]]') > -1)
    return movealong#noise(l:options['skip_syntax'])
  endif
endfunction

" repeat a motion until the given expression returns true
function! movealong#expression(movement, expression, options)
  let l:options = extend({
    \ 'inline'      : 0,
    \ 'skip_syntax' : g:movealong_skip_syntax,
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
  if !l:options['inline']
    return movealong#noise(l:options['skip_syntax'])
  endif
endfunction
