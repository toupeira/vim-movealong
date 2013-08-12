" movealong.txt - Context-aware motion commands
" Author:       Markus Koller <http://github.com/toupeira/>
" Version:      1.0
" License:      Same as Vim itself.  See :help license

let s:error = ""

" set or show last error message
function! movealong#whatswrong(...)
  if a:0 > 0
    let s:error = a:1
  elseif empty(s:error)
    echomsg "[movealong] Nothing's wrong, move along!"
  else
    " echohl ErrorMsg
    echoerr "[movealong] " . s:error
    " echohl none
  endif
endfunction

" show an error and reset the cursor position
function! movealong#abort(message)
  call movealong#whatswrong(a:message)
  echoerr "[movealong] " . a:message
  normal ``
endfunction

" store an error and reset the cursor position
function! movealong#abort(message)
  call movealong#whatswrong(a:message)
  normal ``
endfunction

" get a setting from either a buffer or global variable
function! movealong#setting(key)
  let key = 'movealong_' . a:key
  if exists('b:' . key)
    return eval('b:' . key)
  else
    return eval('g:' . key)
  endif
endfunction

" skip over any syntax noise
function! movealong#noise(...)
  let options = extend({
    \ 'inline'      : 1,
    \ 'initial'     : 0,
    \ 'skip_noise'  : 0,
  \ }, a:0 > 0 ? a:1 : {})

  return movealong#until('w', options)
endfunction

"  repeat a motion until the given condition is met
function! movealong#until(motion, ...)
  let last_arg = a:0 > 0 ? a:000[a:0 - 1] : 0
  let options = extend({
    \ 'inline'      : 0,
    \ 'initial'     : 1,
    \ 'expression'  : '',
    \ 'max_motions' : movealong#setting('max_motions'),
    \ 'syntax'      : [],
    \ 'skip_noise'  : 1,
    \ 'skip_punct'  : 1,
    \ 'skip_syntax' : movealong#setting('skip_syntax'),
    \ 'skip_words'  : movealong#setting('skip_words'),
    \ 'cross_lines' : 1,
    \ 'cross_eof'   : 0,
  \ }, (type(last_arg) == type({})) ? last_arg : {})
  "\ 'skip_syntax' : options['inline'] ? movealong#setting('skip_syntax_inline') : movealong#setting('skip_syntax'),

  " look for string arguments
  if a:0 > 0 && type(a:1) == type('')
    if options['expression'] == 1
      " use the first argument as the expression
      let options['expression'] = a:1
    else
      " use the first argument as a list of syntax groups
      let options['syntax'] = split(a:1, ',')

      if a:0 > 1 && type(a:2) == type('')
        " use the second argument as a list of ignored syntax groups
        let options['skip_syntax'] = split(a:2, ',')
      endif
    endif
  endif

  let word = ''
  let line_text = ''
  let syntax = {}
  let motions = 0

  " add current position to jumplist
  normal m`

  while 1
    if motions > options['max_motions']
      " stop if the maximum number of motions was reached
      call movealong#error("Stopped because maximum number of motions '" . options['max_motions'] . "' was reached")
      return
    endif

    " run the motion
    if options['initial'] || motions > 0
      let last_pos = [ line('.'), col('.') ]
      silent! execute "normal " . a:motion
      let pos = [ line('.'), col('.') ]

      if !options['cross_lines'] && pos[0] != last_pos[0]
        " stop at beginning or end of line
        call movealong#abort("Stopped because motion '" . a:motion . "' crossed line")
        return
      elseif !options['cross_eof'] && ((pos[1] == 1 && last_pos[1] == line('$')) || (pos[1] == line('$') && last_pos[1] == 1))
        " stop at first or last line
        call movealong#abort("Stopped at beginning/end of file")
        return
      elseif pos == last_pos
        " stop if the motion didn't change the cursor position
        call movealong#abort("Stopped because motion '" . a:motion . "'didn't change cursor position")
        return
      endif
    endif
    let motions += 1

    " get inner word under cursor
    let register = $"
    normal yiw
    let word = getreg()
    call setreg('', register)

    " get text of current line, strip whitespace
    let line_text = substitute(getline('.'), ' ', '', 'g')

    if match(line_text, '[^ \t]') == -1
      " skip blank lines
      call movealong#whatswrong("Skipped blank line")
      continue
    elseif options['skip_punct'] && match(options['inline'] ? word : line_text, '\v^[[:punct:]]+$') > -1
      " skip punctuation
      call movealong#whatswrong("Skipped punctuation")
      continue
    elseif !empty(options['skip_words']) && index(options['skip_words'], options['inline'] ? word : line_text) > -1
      " skip lines that only consist of an ignored word
      call movealong#whatswrong("Skipped word")
      continue
    endif

    if !empty(options['expression'])
      if eval(options['expression'])
        call movealong#whatswrong("Stopped because expression returned true")
        break
      else
        call movealong#whatswrong("Skipped because expression returned false")
        continue
      endif
    endif

    let syntax = movealong#syntax#current()

    if !empty(options['syntax'])
      if movealong#syntax#match(syntax, options['syntax'])
        " stop if syntax matches
        call movealong#whatswrong("Stopped because syntax matched")
        break
      else
        " skip lines that don't match the syntax
        call movealong#whatswrong("Skipped syntax")
        continue
      endif
    endif

    " skip ignored syntax types
    if !empty(options['skip_syntax']) && movealong#syntax#match(syntax, options['skip_syntax'])
      if syntax['name'] == 'Comment' || line_text == word || options['inline']
        call movealong#whatswrong("Skipped ignored syntax")
        continue
      endif
    endif

    break
  endwhile

  " skip noise
  if options['skip_noise']
    call movealong#noise()
  endif
endfunction
