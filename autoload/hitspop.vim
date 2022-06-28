" Maintainer: obcat <obcat@icloud.com>
" License:    MIT License


function! s:init() abort "{{{
  let g:hitspop_line       = get(g:, 'hitspop_line', 'wintop')
  let g:hitspop_line_mod   = get(g:, 'hitspop_line_mod', 0)
  let g:hitspop_column     = get(g:, 'hitspop_column', 'winright')
  let g:hitspop_column_mod = get(g:, 'hitspop_column_mod', 0)
  let g:hitspop_zindex = get(g:, 'hitspop_zindex', 50)
  let g:hitspop_minwidth = get(g:, 'hitspop_minwidth', 20)
  let g:hitspop_maxwidth = get(g:, 'hitspop_maxwidth', 30)
  let g:hitspop_timeout = get(g:, 'hitspop_timeout', 10)
  let s:HL_NORMAL   = 'hitspopNormal'
  let s:HL_ERRORMSG = 'hitspopErrorMsg'
  exe 'hi default link' s:HL_NORMAL 'Pmenu'
  exe 'hi default link' s:HL_ERRORMSG 'Pmenu'

  let s:ERROR_MSGS = #{
    \ invalid:  'Invalid',
    \ timeout:  'Timed out',
    \ notfound: 'No results',
    \ }
  let s:PADDING = [0, 1, 0, 1]
  let s:POPUP_STATIC_OPTIONS = #{
    \ zindex:  g:hitspop_zindex,
    \ padding: s:PADDING,
    \ highlight: s:HL_NORMAL,
    \ callback: {-> s:unlet_popup_id()},
    \ }
  let s:UP   = 1
  let s:DOWN = 0
  let s:prev_search_pattern = ''
  let s:prev_bufinfo = []
  let s:timeout_counter = 0
  let s:notfound_flag = s:DOWN
  let s:invalid_flag  = s:DOWN
endfunction "}}}


call s:init()

" This function is called on CursorMoved, CursorMovedI, CursorHold, and WinEnter
function! hitspop#main() abort "{{{
  if !v:hlsearch || get(b:, 'hitspop_disable', 0)
    \            || get(b:, 'hitspop_blocked', 0)
    \            || get(g:, 'hitspop_disable', 0)
    \            || empty(@/)
    call s:delete_popup_if_exists()
    return
  endif

  let coord = s:get_coord()

  if !s:popup_exists()
    let s:popup_id = s:create_popup(coord)
    call setbufvar(winbufnr(s:popup_id), '&filetype', 'hitspop')
  else
    let opts = popup_getoptions(s:popup_id)
    if empty(opts)
      " It is assumed that the popup callback was not called due to some accident, so call it.
      call s:unlet_popup_id()
      return
    endif
    if [opts.line, opts.col] != [coord.line, coord.col]
      call s:move_popup(coord.line, coord.col)
    endif

    call s:update_content()
  endif
endfunction "}}}


" This function is called on WinLeave.
" This matters when leaving tab page.
function! hitspop#clean() abort "{{{
  call s:delete_popup_if_exists()
endfunction "}}}


" This function is called on TerminalOpen.
function! hitspop#define_autocmds_for_terminal_buffer(bufnr) abort "{{{
  exe printf('augroup hitspop-autocmds-for-terminal-buffer-%d', a:bufnr)
    autocmd!
    " Don't show popup in terminal-job mode.
    exe printf('autocmd SafeState <buffer=%d> call s:delete_popup_if_exists_in_terminal_job_mode()', a:bufnr)
  augroup END
endfunction "}}}


function! s:create_popup(coord) abort "{{{
  return popup_create(
    \ s:get_content(),
    \ deepcopy(s:POPUP_STATIC_OPTIONS)->extend(a:coord)
    \ )
endfunction "}}}

function! s:delete_popup_if_exists() abort "{{{
  if s:popup_exists()
    call popup_close(s:popup_id)
  endif
endfunction "}}}

function! s:delete_popup_if_exists_in_terminal_job_mode() abort "{{{
  if mode() is# 't'
    call s:delete_popup_if_exists()
  endif
endfunction "}}}

function! s:move_popup(line, col) abort "{{{
  call popup_move(s:popup_id, #{line: a:line, col: a:col})
endfunction "}}}


function! s:update_content() abort "{{{
  call popup_settext(s:popup_id, s:get_content())
endfunction "}}}


function! s:popup_exists() abort "{{{
  return exists('s:popup_id')
endfunction "}}}


function! s:unlet_popup_id() abort "{{{
  unlet s:popup_id
endfunction "}}}


" Return search results
" NOTE: This function try to return results without running searchcount()
" because it can be slow even with a small timeout value.
function! s:get_content() abort "{{{
  let bufinfo = [bufnr(), b:changedtick]
  if @/ isnot# s:prev_search_pattern
    let s:invalid_flag    = s:DOWN
    let s:timeout_counter = 0
    let s:notfound_flag   = s:DOWN
  elseif bufinfo != s:prev_bufinfo
    let s:timeout_counter = 0
    let s:notfound_flag   = s:DOWN
  endif
  let s:prev_search_pattern = @/
  let s:prev_bufinfo = bufinfo

  let search_pattern = strtrans(@/)

  if s:invalid_flag is s:UP
    return s:format(search_pattern, s:ERROR_MSGS.invalid)
  endif
  if s:timeout_counter == 3
    return s:format(search_pattern, s:ERROR_MSGS.timeout)
  endif
  if s:notfound_flag is s:UP
    return s:format(search_pattern, s:ERROR_MSGS.notfound)
  endif

  try
    let result = searchcount(#{maxcount: 0, timeout: g:hitspop_timeout})
  catch
    " Error: @/ is invalid search pattern (E54, E65, E944, ...)
    let s:invalid_flag = s:UP
    return s:format(search_pattern, s:ERROR_MSGS.invalid)
  endtry

  if result.incomplete == 1
    let s:timeout_counter += 1
    return s:format(search_pattern, s:ERROR_MSGS.timeout)
  endif
  let s:timeout_counter = 0

  if result.total == 0
    let s:notfound_flag = s:UP
    return s:format(search_pattern, s:ERROR_MSGS.notfound)
  endif

  return s:format(
    \ search_pattern,
    \ printf('%*d of %d', len(result.total), result.current, result.total)
    \ )
endfunction "}}}


function! s:format(pattern, result) abort "{{{
  let padding = s:PADDING[1] + s:PADDING[3]
  let result_width = strwidth(a:result)
  let separator = "\<Space>\<Space>"
  let separator_width = strwidth(separator)
  let patternfield_minwidth = g:hitspop_minwidth - (padding + separator_width + result_width)
  let patternfield_maxwidth = g:hitspop_maxwidth - (padding + separator_width + result_width)
  let truncation_symbol = '..'

  let content = printf('%-*S',
    \ patternfield_minwidth,
    \ patternfield_maxwidth < strwidth(a:pattern)
    \   ? s:truncate(a:pattern, truncation_symbol, patternfield_maxwidth)
    \   : a:pattern,
    \ )
  let content .= separator
  let content .= a:result
  return content
endfunction "}}}


function! s:truncate(target, symbol, width) "{{{
  return printf('%.*S%s',
    \ a:width - strwidth(a:symbol),
    \ a:target,
    \ a:symbol
    \ )
endfunction "}}}


" Return dictionary used to specify popup position
function! s:get_coord() abort "{{{
  let [line, col] = win_screenpos(0)
  if !empty(menu_info('WinBar', 'a'))
    let line += 1
  endif
  if g:hitspop_line is# 'wintop'
    let pos = 'top'
  elseif g:hitspop_line is# 'winbot'
    let pos = 'bot'
    let line += winheight(0) - 1
  endif
  if g:hitspop_column is# 'winleft'
    let pos .= 'left'
  elseif g:hitspop_column is# 'winright'
    let pos .= 'right'
    let col += winwidth(0) - 1
  endif
  let line += g:hitspop_line_mod
  let col  += g:hitspop_column_mod
  return #{pos: pos, line: line, col: col}
endfunction "}}}


" This is called from syntax/hitspop.vim
function! hitspop#define_syntax() abort "{{{
  let delimiter = '/'
  for msg in values(s:ERROR_MSGS)
    exe 'syn match' s:HL_ERRORMSG delimiter . escape(msg, delimiter) . '\s*$' . delimiter
  endfor
endfunction "}}}


" API function to get popup id
function! hitspop#getpopupid() abort "{{{
  return get(s:, 'popup_id', '')
endfunction "}}}
