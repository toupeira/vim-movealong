" movealong.txt - Context-aware motion commands
" Author:       Markus Koller <http://github.com/toupeira/>
" Version:      1.0
" License:      Same as Vim itself.  See :help license

let s:debug = 0

" set or show last error message
function! movealong#whatswrong(...)
  if a:0 > 0
    let s:error = a:1

    if s:debug
      call movealong#whatswrong()
    endif
  elseif exists('s:error')
    echohl WarningMsg
    let message = "[movealong] " . s:error

    if exists('s:error_pos')
      let message .= " [pos" . join(s:error_pos[0], '/') . "]"
      let message .= " [last:"     . join(s:error_pos[1], '/') . "]"
    endif

    if exists('s:error_syntax')
      let message .= " [syntax:" . s:error_syntax['name'] . "/" . s:error_syntax['original'] . "]"
    endif

    echomsg message
    echohl none
  else
    echohl MoreMsg
    echomsg "[movealong] Nothing to see here, move along!"
    echohl none
  endif
endfunction

"  repeat a motion until the given condition is met
function! movealong#until(...)
  let options = {
    \ 'debug'       : 0,
    \ 'defaults'    : 0,
    \ 'syntax'      : [],
    \ 'expression'  : '',
    \ 'pattern'     : '',
    \ 'inline'      : 0,
    \ 'initial'     : 1,
    \ 'cross_lines' : 1,
    \ 'cross_eof'   : 0,
    \ 'max_motions' : movealong#util#setting('max_motions'),
  \ }

  " parse arguments
  let [ options, motion ] = movealong#util#parse_options(options, a:000)
  if empty(motion)
    echoerr "Motion argument required"
    return
  endif

  let s:debug = options['debug']

  " enable inline mode for simple characterwise motions
  if match(motion, '\v[wWeEbBfFtThl]') > -1
    let options['inline'] = 1
  endif

  if options['defaults']
    " add default skip settings
    let options = extend({
      \ 'skip_blank'  : 1,
      \ 'skip_punct'  : 1,
      \ 'skip_noise'  : 1,
      \ 'skip_syntax' : movealong#util#setting('skip_syntax'),
      \ 'skip_words'  : movealong#util#setting('skip_words'),
    \ }, options)
  else
    let options = extend({
      \ 'skip_blank'  : 0,
      \ 'skip_punct'  : 0,
      \ 'skip_noise'  : 0,
      \ 'skip_syntax' : [],
      \ 'skip_words'  : [],
    \ }, options)
  endif

  " transform syntax groups and skipwords into regexes
  let options['syntax']      = empty(options['syntax'])      ? '' : '\v^(' . join(options['syntax'], '|') . ')$'
  let options['skip_syntax'] = empty(options['skip_syntax']) ? '' : '\v^(' . join(options['skip_syntax'], '|') . ')$'
  let options['skip_words']  = empty(options['skip_words'])  ? '' : '\v^(' . join(options['skip_words'], '|') . ')$'

  let word = ''
  let line_text = ''
  let syntax = {}
  let motions = 0

  let pos = []
  let last_pos = []
  let last_two_pos = []

  " add current position to jumplist
  normal m`

  while 1
    if motions > options['max_motions']
      " stop if the maximum number of motions was reached
      call movealong#util#error("Stopped because maximum number of motions '" . options['max_motions'] . "' was reached")
      return
    endif

    " run the motion
    if options['initial'] || motions > 0
      " open folds on the current line
      if foldclosed('.') > -1
        foldopen!
      endif

      let last_pos = [ line('.'), col('.') ]
      silent! execute "normal " . motion
      let pos = [ line('.'), col('.') ]

      " store position for error messages
      let s:error_pos = [ pos, last_pos ]

      if !options['cross_lines'] && pos[0] != last_pos[0]
        " stop at beginning or end of line
        call movealong#util#abort("Stopped because motion '" . motion . "' crossed line")
        return
      elseif !options['cross_eof'] && ((pos[1] == 1 && last_pos[1] == line('$')) || (pos[1] == line('$') && last_pos[1] == 1))
        " stop at first or last line
        call movealong#util#abort("Stopped at beginning/end of file")
        return
      elseif pos == last_pos
        " stop if the motion didn't change the cursor position
        call movealong#util#abort("Stopped because motion '" . motion . "' didn't change cursor position")
        return
      elseif [ pos, last_pos ] == last_two_pos
        " stop if the motion doesn't seem to actually move
        call movealong#util#abort("Stopped because motion '" . motion . "' seems to be stuck")
        return
      endif
    endif

    let motions += 1
    let last_two_pos = [ pos, last_pos ]

    " get inner word under cursor
    let register = $"
    silent! normal yiw
    let word = getreg()
    call setreg('', register)

    " get text of current line, strip whitespace
    let line_text = substitute(getline('.'), '\v^\s*(.*)\s*$', '\1', 'g')
    let match_text = options['inline'] ? word : line_text

    " get current syntax group and store for error messages
    let syntax = movealong#util#syntax()
    let s:error_syntax = syntax

    if options['skip_blank'] && match(match_text, '[^ \t]') == -1
      " skip blank lines
      call movealong#whatswrong("Skipped blank line")
      continue
    elseif options['skip_punct'] && match(match_text, '\v^[[:punct:]]+$') > -1
      " skip punctuation
      call movealong#whatswrong("Skipped punctuation '" . match_text . "'")
      continue
    elseif !empty(options['skip_words']) && match(match_text, options['skip_words']) > -1
      " skip specified words
      call movealong#whatswrong("Skipped word '" . match_text . "'")
      continue
    end

    " skip ignored syntax groups
    if !empty(options['skip_syntax']) && movealong#util#match_syntax(syntax, options['skip_syntax'])
      " check for overriden words that should not be skipped for this syntax group
      let syntax_overrides = movealong#util#setting('skip_syntax_overrides')
      if has_key(syntax, 'name') && has_key(syntax_overrides, syntax['name'])
        let overrides = syntax_overrides[syntax['name']]
      elseif has_key(syntax, 'original') && has_key(syntax_overrides, syntax['original'])
        let overrides = syntax_overrides[syntax['original']]
      else
        let overrides = ''
      endif

      if !empty(overrides) && match(match_text, overrides) > -1
        call movealong#whatswrong("Stopped because keyword '" . match_text . "' with syntax group " . syntax['name'] . " was overriden")
        let options['skip_noise'] = 0
        break
      endif

      if syntax['name'] == 'Comment' || line_text == word || options['inline']
        call movealong#whatswrong("Skipped ignored syntax")
        continue
      endif
    endif

    " check expressions
    let match = 0
    let whatswrong = ''

    if !empty(options['expression'])
      if eval(options['expression'])
        call movealong#whatswrong("Stopped because expression returned true")
        let match = 1
      else
        let whatswrong = "Skipped because expression returned false"
      endif
    endif

    " check patterns
    if !empty(options['pattern'])
      if match(match_text, options['pattern']) > -1
        call movealong#whatswrong("Stopped because word '" . match_text . "' matched the pattern '" . options['pattern'] . "'")
        let match = 1
      else
        let whatswrong = "Skipped because word '" . match_text . "' didn't match the pattern '" . options['pattern'] . "'"
      endif
    endif

    " check syntax groups
    if !empty(options['syntax'])
      if movealong#util#match_syntax(syntax, options['syntax'])
        " stop if syntax matches
        call movealong#whatswrong("Stopped because syntax matched")
        let match = 1
      else
        " skip lines that don't match the syntax
        let whatswrong = "Skipped syntax"
      endif
    endif

    if !match
      call movealong#whatswrong(whatswrong)
      continue
    endif

    break
  endwhile

  if options['skip_noise']
    call movealong#skip_noise()
  endif
endfunction

" skip only over blank lines, punctuation and syntax noise
function! movealong#skip_noise(...)
  let options = {
    \ 'defaults'    : 1,
    \ 'inline'      : 1,
    \ 'initial'     : 0,
    \ 'skip_noise'  : 0,
  \ }

  return call('movealong#until', [ 'w', options ] + a:000)
endfunction
