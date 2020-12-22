" Maintainer: obcat <obcat@icloud.com>
" License:    MIT License


function! s:init() abort "{{{
  let s:HL_NORMAL   = 'hitspopNormal'
  let s:HL_ERRORMSG = 'hitspopErrorMsg'
  exe 'hi default link' s:HL_NORMAL 'Pmenu'
  exe 'hi default link' s:HL_ERRORMSG 'Pmenu'

  let s:popup_position = #{
    \ line: 'wintop',
    \ col: 'winright',
    \ zindex: 50,
    \ }
  if exists('g:hitspop_popup_position')
    call s:override_values(g:hitspop_popup_position, s:popup_position)
  endif
  call s:expand_linecol(s:popup_position)

  let s:error_msgs = #{
    \ invalid:  'Invalid',
    \ empty:    'Empty',
    \ timeout:  'Timed out',
    \ notfound: 'No results',
    \ }
  let s:padding = [0, 1, 0, 1]
  let s:popup_static_options = #{
    \ zindex: s:popup_position.zindex,
    \ padding: s:padding,
    \ highlight: 'hitspopNormal',
    \ callback: 's:unlet_popup_id',
    \ }
  let s:searchcount_options = #{
    \ maxcount: 0,
    \ timeout: 30,
    \ }
endfunction "}}}


function! s:override_values(source, target) abort "{{{
  for key in keys(a:target)
    if has_key(a:source, key)
      let a:target[key] = a:source[key]
    endif
  endfor
endfunction "}}}


function! s:expand_linecol(config) abort "{{{
  for key in ['line', 'col']
    let val = a:config[key]
    let mod = matchstr(val, '[-+][0-9]*')
    let base = trim(val, mod)
    let mod = empty(mod) ? '0' : mod
    let a:config[key] = #{base: base, mod: eval(mod)}
  endfor
endfunction "}}}

call s:init()

" This function is called on CursorMoved, CursorMovedI, CursorHold, and WinEnter
function! hitspop#main() abort "{{{
  if s:hl_is_off()
    call s:delete_popup_if_exists()
    return
  endif

  let coord = s:get_coord(s:popup_position)

  if !s:popup_exists()
    call s:create_popup(coord)
    call setbufvar(winbufnr(s:popup_id), '&filetype', 'hitspop')
  else
    let opts = popup_getoptions(s:popup_id)
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
  let content = s:get_content()
  let options = extend(s:popup_static_options, a:coord)
  let s:popup_id = popup_create(content, options)
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


function! s:hl_is_off() abort "{{{
  return !v:hlsearch
endfunction "}}}


function! s:popup_exists() abort "{{{
  return exists('s:popup_id')
endfunction "}}}


function! s:unlet_popup_id(id, result) abort "{{{
  unlet s:popup_id
endfunction "}}}


" Return search results
function! s:get_content() abort "{{{
  let search_pattern = strtrans(@/)
  try
    let result = searchcount(s:searchcount_options)
  catch /.*/
    " Error: @/ is invalid search pattern (e.g. \1)
    return s:format(search_pattern, s:error_msgs.invalid)
  endtry

  " @/ is empty
  if empty(result)
    return s:format(search_pattern, s:error_msgs.empty)
  endif

  " Timed out
  if result.incomplete
    return s:format(search_pattern, s:error_msgs.timeout)
  endif

  if result.total
    return s:format(search_pattern, printf('%*d of %d', len(result.total), result.current, result.total))
  else
    return s:format(search_pattern, s:error_msgs.notfound)
  endif
endfunction "}}}


function! s:format(search_pattern, result) abort "{{{
  let popup_maxwidth = 30
  let popup_minwidth = 20
  let padding = s:padding[1] + s:padding[3]
  let result_width = strwidth(a:result)
  let separator = "\<Space>\<Space>"
  let separator_width = strwidth(separator)
  let search_pattern_field_maxwidth = popup_maxwidth - (padding + separator_width + result_width)
  let search_pattern_field_minwidth = popup_minwidth - (padding + separator_width + result_width)
  let truncation_text = '..'

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
function! s:get_coord(config) abort "{{{
  let [line, col] = win_screenpos(0)
  if a:config.line.base == 'wintop'
    let pos = 'top'
  elseif a:config.line.base == 'winbot'
    let pos = 'bot'
    let line += winheight(0) - 1
  endif
  if a:config.col.base == 'winleft'
    let pos .= 'left'
  elseif a:config.col.base == 'winright'
    let pos .= 'right'
    let col += winwidth(0) - 1
  endif
  let line += a:config.line.mod
  let col += a:config.col.mod
  return #{pos: pos, line: line, col: col}
endfunction "}}}


function! hitspop#_syntax_args() abort "{{{
  let args = []
  for msg in values(s:error_msgs)
    let args += [[s:HL_ERRORMSG, msg]]
  endfor
  return args
endfunction "}}}


" API function to get popup id
function! hitspop#getpopupid() abort "{{{
  return get(s:, 'popup_id', '')
endfunction "}}}
