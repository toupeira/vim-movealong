" movealong.txt - Context-aware motion commands
" Author:       Markus Koller <http://github.com/toupeira/>
" Version:      1.0
" License:      Same as Vim itself.  See :help license

if exists("g:loaded_movealong") || &cp
  finish
endif
let g:loaded_movealong = 1

" map default keys
if !exists("g:movealong_default_keys")
  let g:movealong_default_keys = 1
endif

" limit number of motions
if !exists("g:movealong_max_motions")
  let g:movealong_max_motions = 1000
endif

" syntax groups to skip
if !exists("g:movealong_skip_syntax")
  let g:movealong_skip_syntax = [ 'Noise', 'Comment', 'Statement', 'cInclude', 'rubyInclude', 'rubyDefine' ]
endif

" words to skip
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
command! -nargs=+ -complete=syntax     MovealongSyntax       call movealong#until(<f-args>)
command! -nargs=+ -complete=syntax     MovealongSyntaxInline call movealong#until(<f-args>, { 'inline' : 1 })
command! -nargs=+ -complete=expression MovealongExpression   call movealong#until(<f-args>, { 'expression' : 1 })
command! -nargs=0                      MovealongNoise        call movealong#noise()
command! -nargs=0                      MovealongWhatsWrong   call movealong#whatswrong()

" map default keys
if g:movealong_default_keys
  nmap <silent> <Space>         :MovealongSyntaxInline w<CR>
  nmap <silent> <S-Space>       :MovealongSyntaxInline b<CR>

  nmap <silent> <Tab>           :MovealongSyntax zoj^<CR>
  nmap <silent> <S-Tab>         :MovealongSyntax zok^<CR>

  nmap <silent><expr> <C-Tab>   ":MovealongExpression zoj^ indent('.')==" . indent('.') . "<CR>"
  nmap <silent><expr> <C-S-Tab> ":MovealongExpression zok^ indent('.')==" . indent('.') . "<CR>"
endif
