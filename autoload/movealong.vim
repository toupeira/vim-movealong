" movealong.vim - Move along, nothing to see here.
" Author:       Markus Koller
" Version:      1.0
" License:      Same as Vim itself.  See :help license

let s:error = ""

" store the last error message
function! movealong#error(message)
  let s:error = a:message
endfunction

" store an error and reset the cursor position
function! movealong#abort(message)
  call movealong#error(a:message)
  normal ``
endfunction

" get a setting from either the buffer or the global variable
function! movealong#setting(key)
  let l:key = 'movealong_' . a:key
  if exists('b:' . l:key)
    return eval('b:' . l:key)
  else
    return eval('g:' . l:key)
  endif
endfunction

"  repeat a motion until encountering a given syntax type
function! movealong#syntax(motion, ...)
  let l:options = extend({
    \ 'inline'      : 0,
    \ 'syntax'      : movealong#setting('syntax'),
    \ 'max_motions' : movealong#setting('max_motions'),
    \ 'cross_lines' : movealong#setting('cross_lines'),
    \ 'skip_noise'  : movealong#setting('skip_noise'),
    \ 'skip_punct'  : movealong#setting('skip_punct'),
    \ 'skip_words'  : movealong#setting('skip_words'),
  \ }, (a:0 > 0 && type(a:1) == type({})) ? a:1 : {})

  let l:options = extend(l:options, {
    \ 'skip_syntax' : l:options['inline'] ? movealong#setting('skip_syntax_inline') : movealong#setting('skip_syntax')
  \ })

  if a:0 > 0 && type(a:1) == type('')
    let l:options['syntax'] = split(a:1, ',')
  endif

  if a:0 > 1 && type(a:2) == type('')
    let l:options['skip_syntax'] = split(a:2, ',')
  endif

  if a:0 > 0 && type(a:000[a:0 - 1]) == type({})
    let l:options = extend(l:options, a:000[a:0 - 1])
  endif

  let l:word = ''
  let l:line_text = ''
  let l:syntax = {}
  let l:motions = 0

  " add current position to jumplist
  normal m`

  while 1
    " run the motion
    let l:last_pos = [ line('.'), col('.') ]
    silent! execute "normal " . a:motion
    let l:pos = [ line('.'), col('.') ]

    let l:motions += 1
    if l:motions >= l:options['max_motions']
      " stop if the maximum number of motions was reached
      return movealong#abort("Stopped because maximum number of motions '" . l:options['max_motions'] . "' was reached")
    elseif !l:options['cross_lines'] && l:pos[0] != l:last_pos[0]
      " stop if we don't want to cross lines
      return movealong#abort("Stopped because motion '" . a:motion . "' crossed line")
    elseif l:pos == l:last_pos
      " stop if the motion didn't change the cursor position
      return movealong#abort("Stopped because motion '" . a:motion . "'didn't change cursor position")
    endif

    " get inner word under cursor
    let l:register = $"
    normal yiw
    let l:word = getreg()
    call setreg('', l:register)

    " get text of current line, strip whitespace
    let l:line_text = substitute(getline('.'), ' ', '', 'g')

    if match(l:line_text, '[^ \t]') == -1
      " skip blank lines
      call movealong#error("Skipped blank line")
      continue
    elseif l:options['skip_punct'] && match(l:options['inline'] ? l:word : l:line_text, '\v^[[:punct:]]+$') > -1
      " skip punctuation
      call movealong#error("Skipped punctuation")
      continue
    elseif !empty(l:options['skip_words']) && index(l:options['skip_words'], l:options['inline'] ? l:word : l:line_text) > -1
      " skip lines that only consist of an ignored word
      call movealong#error("Skipped word")
      continue
    endif

    let l:syntax = movealong#syntax#current()

    if !empty(l:options['syntax'])
      if movealong#syntax#match(l:syntax, l:options['syntax'])
        " stop if syntax matches
        call movealong#error("Stopped because syntax matched")
        break
      else
        " skip lines that don't match the syntax
        call movealong#error("Skipped syntax")
        continue
      endif
    endif

    " skip ignored syntax types
    if !empty(l:options['skip_syntax']) && movealong#syntax#match(l:syntax, l:options['skip_syntax'])
      if l:syntax['name'] == 'Comment' || l:line_text == l:word || l:options['inline']
        call movealong#error("Skipped ignored syntax")
        continue
      endif
    endif

    " stop at the first and last line
    if l:pos[0] == 1 || l:pos[0] == line('$')
      return movealong#abort("Stopped at beginning/end of file")
    endif

    break
  endwhile

  " skip noise
  if l:options['skip_noise']
    return movealong#syntax#noise()
  endif
endfunction

" repeat a motion until the given expression returns true
function! movealong#expression(motion, expression, ...)
  let l:options = extend({
    \ 'inline'      : 0,
    \ 'max_motions' : movealong#setting('max_motions'),
    \ 'cross_lines' : movealong#setting('cross_lines'),
    \ 'skip_noise'  : 0,
  \ }, (a:0 > 0 && type(a:1) == type({})) ? a:1 : {})

  let l:options = extend(l:options, {
    \ 'skip_syntax' : l:options['inline'] ? movealong#setting('skip_syntax_inline') : movealong#setting('skip_syntax')
  \ })

  let l:motions = 0

  " add current position to jumplist
  normal m`

  while 1
    " run the motion
    let l:last_pos = [ line('.'), col('.') ]
    silent! execute "normal " . a:motion
    let l:pos = [ line('.'), col('.') ]

    let l:motions += 1
    if l:motions >= l:options['max_motions']
      " stop if the maximum number of motions was reached
      return movealong#abort("Stopped because maximum number of motions '" . l:options['max_motions'] . "' was reached")
    elseif !l:options['cross_lines'] && l:pos[0] != l:last_pos[0]
      " stop if we don't want to cross lines
      return movealong#abort("Stopped because motion '" . a:motion . "' crossed line")
    elseif l:pos == l:last_pos
      " stop if the motion didn't change the cursor position
      return movealong#abort("Stopped because motion '" . a:motion . "'didn't change cursor position")
    endif

    " stop at the first and last line
    if l:pos[0] == 1 || l:pos[0] == line('$')
      return movealong#abort("Stopped at beginning/end of file")
    endif

    if eval(a:expression)
      call movealong#error("Stopped because expression returned true")
      break
    endif
  endwhile

  " skip noise
  if l:options['skip_noise']
    return movealong#syntax#noise()
  endif
endfunction

" show last error message
function! movealong#whatswrong()
  if empty(s:error)
    echomsg "[movealong] Nothing's wrong, move along!"
  else
    echohl ErrorMsg
    echomsg "[movealong] " . s:error
    echohl none
  endif
endfunction
