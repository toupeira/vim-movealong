" movealong.txt - Context-aware motion commands
" Author:       Markus Koller <http://github.com/toupeira/>
" Version:      1.0
" License:      Same as Vim itself.  See :help license

"  repeat a motion until the given condition is met
function! movealong#until(...)
  let options = {
    \ 'syntax'       : [],
    \ 'expression'   : '',
    \ 'pattern'      : '',
    \ 'inline'       : 0,
    \ 'initial'      : 1,
    \ 'cross_lines'  : 1,
    \ 'cross_eof'    : 0,
    \ 'skip_blank'   : 1,
    \ 'skip_punct'   : 1,
    \ 'skip_words'   : movealong#util#setting('skip_words'),
    \ 'max_motions'  : movealong#util#setting('max_motions'),
  \ }

  " parse arguments
  let [ options, motion ] = movealong#util#parse_options(options, a:000)
  if empty(motion)
    echoerr "Motion argument required"
    return
  endif

  " don't skip noise by default if an expression or pattern is given
  if !has_key(options, 'skip_noise')
    let options['skip_noise'] = (empty(options['expression']) && empty(options['pattern']))
  endif

  " don't skip default syntax groups if matching for syntax
  if !has_key(options, 'skip_syntax')
    let options['skip_syntax'] = (empty(options['syntax']) ? movealong#util#setting('skip_syntax') : [])
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
      call movealong#util#whatswrong(pos, last_pos)

      " get current syntax group
      let syntax = movealong#util#syntax()
      let s:error_syntax = syntax

      " store syntax for error messages
      call movealong#util#whatswrong(syntax)

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

    if !empty(options['pattern'])
      if match(match_text, options['pattern']) > -1
        call movealong#util#whatswrong("Stopped because word '" . match_text . "' matched the pattern '" . options['pattern'] . "'")
        break
      else
        call movealong#util#whatswrong("Skipped because word '" . match_text . "' didn't match the pattern '" . options['pattern'] . "'")
        continue
      endif
    endif

    if options['skip_blank'] && match(match_text, '[^ \t]') == -1
      " skip blank lines
      call movealong#util#whatswrong("Skipped blank line")
      continue
    elseif options['skip_punct'] && word != line_text && match(match_text, '\v^[[:punct:]]+$') > -1
      " skip punctuation
      call movealong#util#whatswrong("Skipped punctuation '" . match_text . "'")
      continue
    endif

    if !empty(options['expression'])
      if eval(options['expression'])
        call movealong#util#whatswrong("Stopped because expression returned true")
        break
      else
        call movealong#util#whatswrong("Skipped because expression returned false")
        continue
      endif
    endif

    if !empty(options['syntax'])
      if movealong#util#match_syntax(syntax, options['syntax'])
        " stop if syntax matches
        call movealong#util#whatswrong("Stopped because syntax matched")
        break
      else
        " skip lines that don't match the syntax
        call movealong#util#whatswrong("Skipped syntax")
        continue
      endif
    endif

    if !empty(options['skip_words']) && match(match_text, options['skip_words']) > -1
      " skip lines that only consist of an ignored word
      call movealong#util#whatswrong("Skipped word '" . match_text . "'")
      continue
    elseif !empty(options['skip_syntax']) && movealong#util#match_syntax(syntax, options['skip_syntax'])
      " skip ignored syntax groups
      let syntax_overrides = movealong#util#setting('skip_syntax_overrides')
      if has_key(syntax, 'name') && has_key(syntax_overrides, syntax['name'])
        let overrides = syntax_overrides[syntax['name']]
      elseif has_key(syntax, 'original') && has_key(syntax_overrides, syntax['original'])
        let overrides = syntax_overrides[syntax['original']]
      else
        let overrides = ''
      endif

      if !empty(overrides) && match(match_text, overrides) > -1
        call movealong#util#whatswrong("Stopped because keyword '" . match_text . "' with syntax group " . syntax['name'] . " was overriden")
        let options['skip_noise'] = 0
        break
      endif

      if syntax['name'] == 'Comment' || line_text == word || options['inline']
        call movealong#util#whatswrong("Skipped ignored syntax")
        continue
      endif
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
    \ 'inline'      : 1,
    \ 'initial'     : 0,
    \ 'skip_noise'  : 0,
  \ }

  return call('movealong#until', [ 'w', options ] + a:000)
endfunction
