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
  autocmd CursorMoved,CursorMovedI,CursorHold,WinEnter,VimResized * call hitspop#main()
  if exists('##WinScrolled')
    autocmd WinScrolled * call hitspop#main()
  endif
  autocmd WinLeave * call hitspop#clean()
  autocmd TerminalOpen * call hitspop#define_autocmds_for_terminal_buffer(expand('<abuf>'))
augroup END

command! HitsPopEnable  let g:hitspop_disable = 0
command! HitsPopDisable let g:hitspop_disable = 1

let g:loaded_hitspop = 1
