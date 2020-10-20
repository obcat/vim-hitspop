let s:save_cpo = &cpo
set cpo&vim

if exists('g:loaded_hitspop')
  finish
endif

if !exists('*searchcount')
  finish
endif

augroup hitspop-autocmds | autocmd! | augroup END

function! s:autocmd() abort
  autocmd hitspop-autocmds CursorHold,CursorMoved,CursorMovedI,WinEnter *
    \ call hitspop#main()
  autocmd hitspop-autocmds WinLeave * call hitspop#clean()
endfunction

if !exists(':HitsPopEnable')
  command HitsPopEnable call s:autocmd()
endif
if !exists(':HitsPopDisable')
  command HitsPopDisable
    \ call hitspop#clean() | autocmd! hitspop-autocmds
endif

call s:autocmd()
hi default link HitsPopPopup Pmenu


let g:loaded_hitspop = 1

let &cpo = s:save_cpo
unlet s:save_cpo
