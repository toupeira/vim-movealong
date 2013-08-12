" movealong.vim - Move along, nothing to see here.
" Author:       Markus Koller <http://github.com/toupeira/>
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
  let key = 'movealong_' . a:key
  if exists('b:' . key)
    return eval('b:' . key)
  else
    return eval('g:' . key)
  endif
endfunction

"  repeat a motion until encountering a given syntax type
function! movealong#syntax(motion, ...)
  let options = extend({
    \ 'inline'      : 0,
    \ 'syntax'      : movealong#setting('syntax'),
    \ 'max_motions' : movealong#setting('max_motions'),
    \ 'cross_lines' : movealong#setting('cross_lines'),
    \ 'skip_noise'  : movealong#setting('skip_noise'),
    \ 'skip_punct'  : movealong#setting('skip_punct'),
    \ 'skip_words'  : movealong#setting('skip_words'),
  \ }, (a:0 > 0 && type(a:1) == type({})) ? a:1 : {})

  let options = extend(options, {
    \ 'skip_syntax' : options['inline'] ? movealong#setting('skip_syntax_inline') : movealong#setting('skip_syntax')
  \ })

  if a:0 > 0 && type(a:1) == type('')
    let options['syntax'] = split(a:1, ',')
  endif

  if a:0 > 1 && type(a:2) == type('')
    let options['skip_syntax'] = split(a:2, ',')
  endif

  if a:0 > 0 && type(a:000[a:0 - 1]) == type({})
    let options = extend(options, a:000[a:0 - 1])
  endif

  let word = ''
  let line_text = ''
  let syntax = {}
  let motions = 0

  " add current position to jumplist
  normal m`

  while 1
    " run the motion
    let last_pos = [ line('.'), col('.') ]
    silent! execute "normal " . a:motion
    let pos = [ line('.'), col('.') ]

    let motions += 1
    if motions >= options['max_motions']
      " stop if the maximum number of motions was reached
      return movealong#abort("Stopped because maximum number of motions '" . options['max_motions'] . "' was reached")
    elseif !options['cross_lines'] && pos[0] != last_pos[0]
      " stop if we don't want to cross lines
      return movealong#abort("Stopped because motion '" . a:motion . "' crossed line")
    elseif pos == last_pos
      " stop if the motion didn't change the cursor position
      return movealong#abort("Stopped because motion '" . a:motion . "'didn't change cursor position")
    endif

    " get inner word under cursor
    let register = $"
    normal yiw
    let word = getreg()
    call setreg('', register)

    " get text of current line, strip whitespace
    let line_text = substitute(getline('.'), ' ', '', 'g')

    if match(line_text, '[^ \t]') == -1
      " skip blank lines
      call movealong#error("Skipped blank line")
      continue
    elseif options['skip_punct'] && match(options['inline'] ? word : line_text, '\v^[[:punct:]]+$') > -1
      " skip punctuation
      call movealong#error("Skipped punctuation")
      continue
    elseif !empty(options['skip_words']) && index(options['skip_words'], options['inline'] ? word : line_text) > -1
      " skip lines that only consist of an ignored word
      call movealong#error("Skipped word")
      continue
    endif

    let syntax = movealong#syntax#current()

    if !empty(options['syntax'])
      if movealong#syntax#match(syntax, options['syntax'])
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
    if !empty(options['skip_syntax']) && movealong#syntax#match(syntax, options['skip_syntax'])
      if syntax['name'] == 'Comment' || line_text == word || options['inline']
        call movealong#error("Skipped ignored syntax")
        continue
      endif
    endif

    " stop at the first and last line
    if pos[0] == 1 || pos[0] == line('$')
      return movealong#abort("Stopped at beginning/end of file")
    endif

    break
  endwhile

  " skip noise
  if options['skip_noise']
    return movealong#syntax#noise()
  endif
endfunction

" repeat a motion until the given expression returns true
function! movealong#expression(motion, expression, ...)
  let options = extend({
    \ 'inline'      : 0,
    \ 'max_motions' : movealong#setting('max_motions'),
    \ 'cross_lines' : movealong#setting('cross_lines'),
    \ 'skip_noise'  : 0,
  \ }, (a:0 > 0 && type(a:1) == type({})) ? a:1 : {})

  let options = extend(options, {
    \ 'skip_syntax' : options['inline'] ? movealong#setting('skip_syntax_inline') : movealong#setting('skip_syntax')
  \ })

  let motions = 0

  " add current position to jumplist
  normal m`

  while 1
    " run the motion
    let last_pos = [ line('.'), col('.') ]
    silent! execute "normal " . a:motion
    let pos = [ line('.'), col('.') ]

    let motions += 1
    if motions >= options['max_motions']
      " stop if the maximum number of motions was reached
      return movealong#abort("Stopped because maximum number of motions '" . options['max_motions'] . "' was reached")
    elseif !options['cross_lines'] && pos[0] != last_pos[0]
      " stop if we don't want to cross lines
      return movealong#abort("Stopped because motion '" . a:motion . "' crossed line")
    elseif pos == last_pos
      " stop if the motion didn't change the cursor position
      return movealong#abort("Stopped because motion '" . a:motion . "'didn't change cursor position")
    endif

    " stop at the first and last line
    if pos[0] == 1 || pos[0] == line('$')
      return movealong#abort("Stopped at beginning/end of file")
    endif

    if eval(a:expression)
      call movealong#error("Stopped because expression returned true")
      break
    endif
  endwhile

  " skip noise
  if options['skip_noise']
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
