" movealong.vim - Move along, nothing to see here.
" Author:       Markus Koller <http://github.com/toupeira/>
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

" limit number of motions
if !exists("g:movealong_max_motions")
  let g:movealong_max_motions = 1000
endif

" specify if lines should be crossed by default
if !exists("g:movealong_cross_lines")
  let g:movealong_cross_lines = 1
endif

" specify syntax types to look for
if !exists("g:movealong_syntax")
  let g:movealong_syntax = []
endif

" specify syntax types to skip
if !exists("g:movealong_skip_syntax")
  let g:movealong_skip_syntax = [ 'Noise', 'Comment', 'Statement', 'cInclude', 'rubyInclude', 'rubyDefine' ]
endif

" specify syntax types to skip on inline motions
if !exists("g:movealong_skip_syntax_inline")
  let g:movealong_skip_syntax_inline = [ 'Noise', 'Comment' ]
endif

" skip noise after a successful movement
if !exists("g:movealong_skip_noise")
  let g:movealong_skip_noise = 0
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
command! -nargs=+ -complete=syntax     MovealongSyntax       call movealong#syntax(<f-args>)
command! -nargs=+ -complete=syntax     MovealongSyntaxInline call movealong#syntax(<f-args>, { 'inline' : 1 })
command! -nargs=0                      MovealongNoise        call movealong#syntax#noise()

command! -nargs=+ -complete=expression MovealongExpression   call movealong#expression(<f-args>)

command! -nargs=0                      MovealongWhatsWrong   call movealong#whatswrong()

" set up default maps
nnoremap <silent> <Plug>movealongForward  :MovealongSyntaxInline w<CR>
nnoremap <silent> <Plug>movealongBackward :MovealongSyntaxInline b<CR>

nnoremap <silent> <Plug>movealongDown     :call movealong#syntax('zoj^', { 'skip_noise' : 1 })<CR>
nnoremap <silent> <Plug>movealongUp       :call movealong#syntax('zok^', { 'skip_noise' : 1 })<CR>

nnoremap <silent><expr> <Plug>movealongIndentDown ":MovealongExpression zoj^ indent('.')==" . indent('.') . "<CR>"
nnoremap <silent><expr> <Plug>movealongIndentUp   ":MovealongExpression zok^ indent('.')==" . indent('.') . "<CR>"

" map default keys
if g:movealong_default_keys
  " Space and Shift+Space - move to next/previous useful word
  nmap <silent> <Space>   <Plug>movealongForward
  nmap <silent> <S-Space> <Plug>movealongBackward

  " Tab and Shift+Tab - move to next/previous useful line
  nmap <silent> <Tab>   <Plug>movealongDown
  nmap <silent> <S-Tab> <Plug>movealongUp

  " Ctrl-Tab and Ctrl-Shift+Tab - move to next/previous line with same indent
  nmap <silent> <C-Tab>   <Plug>movealongIndentDown
  nmap <silent> <C-S-Tab> <Plug>movealongIndentUp
endif
