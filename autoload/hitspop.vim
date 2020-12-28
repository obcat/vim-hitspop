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
  let s:HL_NORMAL   = 'hitspopNormal'
  let s:HL_ERRORMSG = 'hitspopErrorMsg'
  exe 'hi default link' s:HL_NORMAL 'Pmenu'
  exe 'hi default link' s:HL_ERRORMSG 'Pmenu'

  let s:ERROR_MSGS = #{
    \ invalid:  'Invalid',
    \ empty:    'Empty',
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
  let s:save_info = []
  let s:timeout_counter = 0
  let s:notfound_counter = 0
endfunction "}}}


call s:init()

" This function is called on CursorMoved, CursorMovedI, CursorHold, and WinEnter
function! hitspop#main() abort "{{{
  if !v:hlsearch
    call s:delete_popup_if_exists()
    return
  endif

  let coord = s:get_coord()

  if !s:popup_exists()
    let s:popup_id = s:create_popup(coord)
    call setbufvar(winbufnr(s:popup_id), '&filetype', 'hitspop')
  else
    let opts = popup_getoptions(s:popup_id)
    if [opts.line, opts.col] != [coord.line, coord.col]
      call s:move_popup(coord.line, coord.col)
    endif

    call s:update_content()
  endif
endfunction "}}}


function! hitspop#clean() abort "{{{
  call s:delete_popup_if_exists()
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
  if empty(@/)
    return s:format('', s:ERROR_MSGS.empty)
  endif

  let info = [@/, bufnr(), b:changedtick]
  if info != s:save_info
    let s:timeout_counter = 0
    let s:notfound_counter = 0
    let s:save_info = info
  endif

  let search_pattern = strtrans(@/)

  if s:timeout_counter == 3
    return s:format(search_pattern, s:ERROR_MSGS.timeout)
  endif
  if s:notfound_counter == 1
    return s:format(search_pattern, s:ERROR_MSGS.notfound)
  endif

  try
    let result = searchcount(#{maxcount: 0, timeout: 10})
  catch /.*/
    return s:format(search_pattern, s:ERROR_MSGS.invalid)
  endtry

  if result.incomplete == 1
    let s:timeout_counter += 1
    return s:format(search_pattern, s:ERROR_MSGS.timeout)
  endif
  let s:timeout_counter = 0

  if result.total == 0
    let s:notfound_counter += 1
    return s:format(search_pattern, s:ERROR_MSGS.notfound)
  endif
  let s:notfound_counter = 0

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


function! hitspop#_syntax_args() abort "{{{
  let args = []
  for msg in values(s:ERROR_MSGS)
    let args += [[s:HL_ERRORMSG, msg]]
  endfor
  return args
endfunction "}}}


" API function to get popup id
function! hitspop#getpopupid() abort "{{{
  return get(s:, 'popup_id', '')
endfunction "}}}
