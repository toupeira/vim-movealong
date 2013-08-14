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

" set or show last error message
function! movealong#util#whatswrong(...)
  if a:0 > 0
    if type(a:1) == type([])
      let s:error_pos = [ a:1, a:2 ]
    elseif type(a:1) == type({})
      let s:error_syntax = a:1
    else
      let s:error = a:1
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

" store an error and reset the cursor position
function! movealong#util#abort(message)
  execute "normal \<Esc>"
  call movealong#util#whatswrong(a:message)
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
function! movealong#util#parse_options(options, args)
  let options = a:options
  let args = copy(a:args)
  let motion = ""

  while !empty(args)
    if type(args[0]) == type({})
      let options = extend(options, args[0])
    elseif type(args[0]) != type('')
      echoerr "Invalid argument '" . args[0] . "'"
      return
    elseif args[0][0] == '-'
      let option = substitute(args[0][1:-1], '-', '_', 'g')
      if option == 'inline'
        let options[option] = 1
      elseif len(args) == 1
        echoerr "Argument required for option '" . option . "'"
        return
      elseif match(option, '\v^(syntax|skip_syntax|skip_words)$') > -1
        let options[option] = split(args[1], ',')
        unlet args[0]
      else
        let options[option] = eval(args[1])
        unlet args[0]
      endif
    elseif args[0][0] == '{'
      let options = extend(options, eval(args[0]))
    elseif empty(motion)
      let motion = args[0]
    else
      echoerr "Passed more than one motion argument"
      return
    endif

    unlet args[0]
  endwhile

  return [ options, motion ]
endfunction
