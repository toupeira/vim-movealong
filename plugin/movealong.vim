" movealong.txt - Context-aware motion commands
" Author:       Markus Koller <http://github.com/toupeira/>
" Version:      1.0
" License:      Same as Vim itself.  See :help license

if exists("g:loaded_movealong") || &cp || !has('syntax')
  finish
endif
let g:loaded_movealong = 1

function! s:check_defined(variable, default)
  if !exists(a:variable)
    let {a:variable} = a:default
  endif
endfunction

call s:check_defined('g:movealong_default_keys', 0)

let g:movealong_default_maps = extend({
  \ 'WordForward'   : '<Space>',
  \ 'WordBackward'  : '<Backspace>',
  \ 'LineForward'      : '<Tab>',
  \ 'LineBackward'        : '<S-Tab>',
  \ 'IndentForward'    : '<Leader>i',
  \ 'IndentBackward'      : '<Leader>I',
  \ 'FunctionForward'  : '<Leader>f',
  \ 'FunctionBackward'    : '<Leader>F',
\ }, exists('g:movealong_default_maps') ? g:movealong_default_maps : {})

call s:check_defined('g:movealong_max_motions', 1000)

call s:check_defined('g:movealong_skip_syntax', [
  \ 'Noise',
  \ 'Comment',
  \ 'Statement',
  \ 'cInclude',
  \ 'rubyInclude',
  \ 'rubyDefine',
  \ 'pythonInclude',
  \ 'phpInclude',
  \ 'phpFCKeyword',
\ ])

call s:check_defined('g:movealong_function_syntax', [
  \ 'vimFuncKey',
  \ 'rubyDefine',
  \ 'pythonFunction',
  \ 'phpFCKeyword',
\ ])

call s:check_defined('g:movealong_skip_words', [
  \ 'fi',
  \ 'end',
  \ 'else',
  \ 'done',
  \ 'then',
  \ 'endif',
  \ 'endfor',
  \ 'endwhile',
  \ 'endfunction',
  \ 'class',
  \ 'module',
  \ 'private',
  \ 'protected',
  \ 'public',
  \ 'static',
  \ 'abstract',
\ ])

" overrides for useful keywords that have an ignored syntax group
call s:check_defined('g:movealong_skip_syntax_overrides', {
  \ 'Statement': '(return|super)',
\ })

" define commands
command! -nargs=+ -complete=command    Movealong                  call movealong#until(<f-args>)
command! -nargs=0                      MovealongWhatsWrong        call movealong#whatswrong()

" set up default maps
nnoremap <silent> <Plug>movealongWordForward  :Movealong w -defaults<CR>
nnoremap <silent> <Plug>movealongWordBackward :Movealong b -defaults<CR>

nnoremap <silent> <Plug>movealongLineForward  :Movealong j^ -defaults<CR>
nnoremap <silent> <Plug>movealongLineBackward :Movealong k^ -defaults<CR>

nnoremap <silent><expr> <Plug>movealongFunctionForward  ":Movealong j^ -defaults -syntax " . join(movealong#util#setting('function_syntax'), ',') . "<CR>"
nnoremap <silent><expr> <Plug>movealongFunctionBackward ":Movealong k^ -defaults -syntax " . join(movealong#util#setting('function_syntax'), ',') . "<CR>"

nnoremap <silent><expr> <Plug>movealongIndentForward    ":Movealong j^ -expression indent('.')==" . indent('.') . "<CR>"
nnoremap <silent><expr> <Plug>movealongIndentBackward   ":Movealong k^ -expression indent('.')==" . indent('.') . "<CR>"

" map default keys
if g:movealong_default_keys
  for [plug, key] in items(g:movealong_default_maps)
    execute "nmap " . key . " <Plug>movealong" . plug
  endfor
endif
