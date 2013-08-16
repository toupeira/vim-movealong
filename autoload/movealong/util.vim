" movealong.txt - Context-aware motion commands
" Author:       Markus Koller <http://github.com/toupeira/>
" Version:      1.0
" License:      Same as Vim itself.  See :help license

" get a setting from either a buffer or global variable
function! movealong#util#setting(key)
  let key = 'movealong_' . a:key
  if exists('b:' . key)
    return eval('b:' . key)
  else
    return eval('g:' . key)
  endif
endfunction

" store an error and reset the cursor position
function! movealong#util#abort(message)
  execute "normal \<Esc>"
  call movealong#whatswrong(a:message)
  normal ``
endfunction

" show an error and reset the cursor position
function! movealong#util#error(message)
  call movealong#util#abort(a:message)
  echoerr "[movealong] " . a:message
endfunction

" get the syntax names for the current cursor position
function! movealong#util#syntax()
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
function! movealong#util#match_syntax(syntax, pattern)
  return (has_key(a:syntax, 'name')     && match(a:syntax['name'],     a:pattern) > -1)
    \ || (has_key(a:syntax, 'original') && match(a:syntax['original'], a:pattern) > -1)
endfunction

" parse option arguments
let s:bool_options = join([ 'defaults', 'inline', 'initial', 'skip_blank', 'skip_punct', 'skip_noise', 'cross_lines', 'cross_eof', 'debug' ], '|')
let s:list_options = join([ 'syntax', 'skip_syntax', 'skip_words' ], '|')
let s:expr_options = join([ 'pattern', 'expression' ], '|')

function! movealong#util#parse_options(options, args)
  let options = a:options
  let args = copy(a:args)
  let motion = ""

  while !empty(args)
    if type(args[0]) == type({})
      " merge options
      let options = extend(options, args[0])
      unlet args[0]
      continue
    elseif type(args[0]) != type('')
      echoerr "Invalid argument '" . args[0] . "'"
      return
    elseif args[0][0] != '-'
      " use as motion
      if empty(motion)
        let motion = args[0]
        unlet args[0]
        continue
      else
        echoerr "Passed more than one motion argument"
        return
      endif
    endif

    " parse options
    let option = substitute(args[0][1:-1], '-', '_', 'g')

    if match(option, '\v^(' . s:bool_options . ')$') > -1
      let options[option] = 1
    elseif match(option, '\v^no-( ' . s:bool_options . ')$') > -1
      let options[option] = 0
    elseif len(args) == 1
      echoerr "Argument required for option '" . option . "'"
      return
    elseif match(option, '\v^(' . s:list_options . ')$') > -1
      let options[option] = split(args[1], ',')
      " delete option argument
      unlet args[0]
    else
      let options[option] = args[1]

      if match(option, '\v^(' . s:expr_options . ')$') > -1
        let options[option] = substitute(options[option], '\v(\<\w+\>)', '\=expand(submatch(1))', 'g')
        let options[option] = substitute(options[option], '\v(\@[^\w[:punct:]]+)', '\=eval(submatch(1))', 'g')
      endif

      " delete option argument
      unlet args[0]
    endif

    " delete option
    unlet args[0]
  endwhile

  return [ options, motion ]
endfunction
