" Maintainer: obcat <obcat@icloud.com>
" License:    MIT License


if exists('g:loaded_hitspop')
  finish
endif

if !exists('*searchcount')
  finish
endif

function! s:autocmd() abort
  augroup hitspop-autocmds
    autocmd!
    autocmd CursorHold,CursorMoved,CursorMovedI,WinEnter * call hitspop#main()
    autocmd WinLeave * call hitspop#clean()
  augroup END
endfunction

if exists(':HitsPopEnable') isnot 2
  command HitsPopEnable call s:autocmd()
endif
if exists(':HitsPopDisable') isnot 2
  command HitsPopDisable call hitspop#clean() | autocmd! hitspop-autocmds
endif

call s:autocmd()
hi default link HitsPopPopup Pmenu


let g:loaded_hitspop = 1
