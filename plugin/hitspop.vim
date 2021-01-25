" Maintainer: obcat <obcat@icloud.com>
" License:    MIT License


if exists('g:loaded_hitspop')
  finish
endif

if !exists('*searchcount')
  finish
endif

augroup hitspop-autocmds
  autocmd!
  autocmd CursorMoved,CursorMovedI,CursorHold,WinEnter * call hitspop#main()
  autocmd WinLeave * call hitspop#clean()
augroup END

command! HitsPopEnable  let g:hitspop_disable = 0
command! HitsPopDisable let g:hitspop_disable = 1

let g:loaded_hitspop = 1
