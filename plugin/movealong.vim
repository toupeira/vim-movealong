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
  let g:movealong_skip_syntax = [ 'Noise', 'Comment', 'Statement', 'PreProc' ]
endif

" specify syntax types to skip on inline movement
if !exists("g:movealong_skip_syntax_inline")
  let g:movealong_skip_syntax_inline = [ 'Noise', 'Comment' ]
endif

" skip punctuation
if !exists("g:movealong_skip_punct")
  let g:movealong_skip_punct = 1
endif

" specify words to skip
if !exists("g:movealong_skip_words")
  let g:movealong_skip_words = [
    \ 'fi',
    \ 'end',
    \ 'else',
    \ 'done',
    \ 'then',
    \ 'endif',
    \ 'endfor',
    \ 'endwhile',
    \ 'endfunction',
  \ ]
endif

" set up commands
command! -nargs=1 MovealongSyntax       call movealong#syntax(<f-args>, {})
command! -nargs=1 MovealongSyntaxInline call movealong#syntax(<f-args>, { 'inline' : 1 })
command! -nargs=+ MovealongExpression   call movealong#expression(<f-args>, {})

" set up default maps
nnoremap <silent> <Plug>movealongForward  :MovealongSyntaxInline w<CR>
nnoremap <silent> <Plug>movealongBackward :MovealongSyntaxInline b<CR>

nnoremap <silent> <Plug>movealongDown     :MovealongSyntax zoj^<CR>
nnoremap <silent> <Plug>movealongUp       :MovealongSyntax zok^<CR>

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
