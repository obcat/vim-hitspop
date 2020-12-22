" Maintainer: obcat <obcat@icloud.com>
" License:    MIT License


function! s:init() abort "{{{
  let g:hitspop_line_axis    = get(g:, 'hitspop_line_axis', 'wintop')
  let g:hitspop_line_coord   = get(g:, 'hitspop_line_coord', 0)
  let g:hitspop_column_axis  = get(g:, 'hitspop_column_axis', 'winright')
  let g:hitspop_column_coord = get(g:, 'hitspop_column_coord', 0)
  let g:hitspop_zindex = get(g:, 'hitspop_zindex', 50)
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
    \ zindex: g:hitspop_zindex,
    \ padding: s:PADDING,
    \ highlight: 'hitspopNormal',
    \ callback: 's:unlet_popup_id',
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
  if win_gettype() ==# 'popup'
    return
  endif
  call s:delete_popup_if_exists()
endfunction "}}}


function! s:create_popup(coord) abort "{{{
  return popup_create(s:get_content(), extend(deepcopy(s:POPUP_STATIC_OPTIONS), a:coord))
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


function! s:unlet_popup_id(id, result) abort "{{{
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

  if result.total
    return s:format(search_pattern, printf('%*d of %d', len(result.total), result.current, result.total))
  else
    return s:format(search_pattern, s:ERROR_MSGS.notfound)
  endif
endfunction "}}}


function! s:format(search_pattern, result) abort "{{{
  const popup_maxwidth = 30
  const popup_minwidth = 20
  const padding = s:PADDING[1] + s:PADDING[3]
  const result_width = strwidth(a:result)
  const separator = "\<Space>\<Space>"
  const separator_width = strwidth(separator)
  const search_pattern_field_maxwidth = popup_maxwidth - (padding + separator_width + result_width)
  const search_pattern_field_minwidth = popup_minwidth - (padding + separator_width + result_width)
  const truncation_text = '..'

  let content = printf('%-*.*S',
   \ search_pattern_field_minwidth,
   \ search_pattern_field_maxwidth,
   \ search_pattern_field_maxwidth < strwidth(a:search_pattern)
   \   ? s:truncate(a:search_pattern, truncation_text, search_pattern_field_maxwidth)
   \   : a:search_pattern,
   \ )
  let content .= separator
  let content .= a:result
  return content
endfunction "}}}


function! s:truncate(target_text, truncation_text, width) "{{{
  return printf('%.*S%s',
   \ a:width - strwidth(a:truncation_text),
   \ a:target_text,
   \ a:truncation_text
   \ )
endfunction "}}}


" Return dictionary used to specify popup position
function! s:get_coord() abort "{{{
  let [line, col] = win_screenpos(0)
  if g:hitspop_line_axis == 'wintop'
    let pos = 'top'
  elseif g:hitspop_line_axis == 'winbot'
    let pos = 'bot'
    let line += winheight(0) - 1
  endif
  if g:hitspop_column_axis == 'winleft'
    let pos .= 'left'
  elseif g:hitspop_column_axis == 'winright'
    let pos .= 'right'
    let col += winwidth(0) - 1
  endif
  let line += g:hitspop_line_coord
  let col += g:hitspop_column_coord
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
