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
  const s:HL_NORMAL   = 'hitspopNormal'
  const s:HL_ERRORMSG = 'hitspopErrorMsg'
  exe 'hi default link' s:HL_NORMAL 'Pmenu'
  exe 'hi default link' s:HL_ERRORMSG 'Pmenu'

  const s:ERROR_MSGS = #{
    \ invalid:  'Invalid',
    \ empty:    'Empty',
    \ timeout:  'Timed out',
    \ notfound: 'No results',
    \ }
  const s:PADDING = [0, 1, 0, 1]
  const s:POPUP_STATIC_OPTIONS = #{
    \ zindex:  g:hitspop_zindex,
    \ padding: s:PADDING,
    \ highlight: s:HL_NORMAL,
    \ callback: {-> s:unlet_popup_id()},
    \ }
endfunction "}}}


call s:init()

" This function is called on CursorMoved, CursorMovedI, CursorHold, and WinEnter
function! hitspop#main() abort "{{{
  if !v:hlsearch
    call s:delete_popup_if_exists()
    return
  endif

  const coord = s:get_coord()

  if !s:popup_exists()
    let s:popup_id = s:create_popup(coord)
    call setbufvar(winbufnr(s:popup_id), '&filetype', 'hitspop')
  else
    const opts = popup_getoptions(s:popup_id)
    if [opts.line, opts.col] != [coord.line, coord.col]
      call s:move_popup(coord.line, coord.col)
    endif

    call s:update_content()
  endif
endfunction "}}}


" This function is called on WinLeave
function! hitspop#clean() abort "{{{
  " Avoid E994 (see https://github.com/obcat/vim-hitspop/issues/5)
  if win_gettype() is# 'popup'
    return
  endif
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
function! s:get_content() abort "{{{
  const search_pattern = strtrans(@/)
  try
    const result = searchcount(#{maxcount: 0, timeout: 30})
  catch /.*/
    " Error: @/ is invalid search pattern (e.g. \1)
    return s:format(search_pattern, s:ERROR_MSGS.invalid)
  endtry

  " @/ is empty
  if empty(result)
    return s:format(search_pattern, s:ERROR_MSGS.empty)
  endif

  " Timed out
  if result.incomplete
    return s:format(search_pattern, s:ERROR_MSGS.timeout)
  endif

  if result.total == 0
    return s:format(search_pattern, s:ERROR_MSGS.notfound)
  else
    return s:format(
      \ search_pattern,
      \ printf('%*d of %d', len(result.total), result.current, result.total)
      \ )
  endif
endfunction "}}}


function! s:format(pattern, result) abort "{{{
  const padding = s:PADDING[1] + s:PADDING[3]
  const result_width = strwidth(a:result)
  const separator = "\<Space>\<Space>"
  const separator_width = strwidth(separator)
  const patternfield_minwidth = g:hitspop_minwidth - (padding + separator_width + result_width)
  const patternfield_maxwidth = g:hitspop_maxwidth - (padding + separator_width + result_width)
  const truncation_symbol = '..'

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
