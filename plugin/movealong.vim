" movealong.vim - Move along, nothing to see here.
" Author:       Markus Koller
" Version:      1.0
" License:      Same as Vim itself.  See :help license

if exists("g:loaded_movealong") || &cp
  finish
endif
let g:loaded_movealong = 1

" enable default key mappings
if !exists("g:movealong_default_keys")
  let g:movealong_default_keys = 1
endif

" specify syntax types to look for
if !exists("g:movealong_syntax")
  let g:movealong_syntax = []
endif

" specify syntax types to skip
if !exists("g:movealong_skip_syntax")
  let g:movealong_skip_syntax = [ 'Comment', 'Noise', 'Special' ]
endif

" specify syntax types to be considered noise
if !exists("g:movealong_noise_syntax")
  let g:movealong_noise_syntax = [ 'Noise', 'Special', 'Statement', 'PreProc' ]
endif

" specify words to skip
if !exists("g:movealong_skip_words")
  let g:movealong_skip_words = [
    \ 'fi',
    \ 'else',
    \ 'done',
    \ 'then',
    \ 'end',
    \ 'endif',
    \ 'endfor',
    \ 'endwhile',
    \ 'endfunction',
    \ '} else {',
  \ ]
endif

" set up commands
command! -nargs=1 MovealongSyntax call movealong#syntax(<f-args>, {})
command! -nargs=1 MovealongSyntaxWithinLine call movealong#syntax(<f-args>, { 'within_line' : 1 })
command! -nargs=+ MovealongExpression call movealong#expression(<f-args>, {})

" set up default maps
nnoremap <silent> <Plug>movealongForward  :MovealongSyntax W<CR>
nnoremap <silent> <Plug>movealongBackward :MovealongSyntax B<CR>
nnoremap <silent> <Plug>movealongDown :MovealongSyntax zoj^<CR>
nnoremap <silent> <Plug>movealongUp   :MovealongSyntax zok^<CR>

nnoremap <silent><expr> <Plug>movealongColumnDown ":MovealongExpression zoj^ indent('.')==" . indent('.') . "<CR>"
nnoremap <silent><expr> <Plug>movealongColumnUp   ":MovealongExpression zok^ indent('.')==" . indent('.') . "<CR>"

" map default keys
if g:movealong_default_keys
  " Space and Shift+Space - move to next/previous useful word
  nmap <silent> <Space>   <Plug>movealongForward
  nmap <silent> <S-Space> <Plug>movealongBackward

  " Tab and Shift+Tab - move to next/previous useful line
  nmap <silent> <Tab>   <Plug>movealongDown
  nmap <silent> <S-Tab> <Plug>movealongUp

  " Ctrl-Tab and Ctrl-Shift+Tab - move to next/previous line with same indent
  nmap <silent> <C-Tab>   <Plug>movealongColumnDown
  nmap <silent> <C-S-Tab> <Plug>movealongColumnUp
endif
