" Maintainer: obcat <obcat@icloud.com>
" License:    MIT License


if exists('g:loaded_hitspop')
  finish
endif

if !exists('*searchcount')
  finish
endif

function! s:register_autocmds() abort
  augroup hitspop-autocmds
    autocmd!
    autocmd CursorMoved,CursorMovedI,CursorHold,WinEnter * call hitspop#main()
    autocmd WinLeave * call hitspop#clean()
  augroup END
endfunction

command! HitsPopEnable  call hitspop#main()  | call s:register_autocmds()
command! HitsPopDisable call hitspop#clean() | autocmd! hitspop-autocmds

call s:register_autocmds()


let g:loaded_hitspop = 1
