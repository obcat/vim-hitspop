" Maintainer: obcat <obcat@icloud.com>
" License:    MIT License


function! s:init() abort "{{{
  let s:show_search_pattern = get(g:, 'hitspop_show_search_pattern', 1)
  let s:popup_zindex = get(g:, 'hitspop_popup_zindex', 50)
  hi default link HitsPopPopup Pmenu

  let s:popup_static_options = #{
    \ zindex: s:popup_zindex,
    \ padding: [0, 1, 0, 1],
    \ highlight: 'HitsPopPopup',
    \ callback: 's:unlet_popup_id',
    \}
  let s:searchcount_options = #{
    \ maxcount: 0,
    \ timeout: 30,
    \ }
endfunction "}}}

call s:init()


" This function is called on CursorMoved, CursorMovedI, CursorHold, and WinEnter
function! hitspop#main() abort "{{{
  if s:hl_is_off()
    call s:delete_popup_if_exists()
    return
  endif

  let coord = s:get_coord()

  if !s:popup_exists()
    call s:create_popup(coord)
  else
    let currpos = popup_getpos(s:popup_id)
    if [currpos.line, currpos.col] != [coord.line, coord.col]
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
  try
    let result = searchcount(s:searchcount_options)
  catch /.*/
    " Error: @/ is invalid search pattern (e.g. \1)
  endtry

  let str = s:show_search_pattern
    \ ? @/ . "\<Space>"
    \ : ''

  if !exists('result')
    return printf('%s[INVALID]', str)
  endif

  " @/ is empty
  if empty(result)
    return '[@/==EMPTY]'
  endif

  " Timed out
  if result.incomplete
    return printf('%s[TIMED_OUT]', str)
  endif

  return printf('%s[%d/%d]', str, result.current, result.total)
endfunction "}}}


" Return dictionary used to specify popup position
function! s:get_coord() abort "{{{
  let [line, col] = win_screenpos(0)
  let col += winwidth(0) - 1
  return #{
   \ pos: 'topright',
   \ line: line,
   \ col: col,
   \}
endfunction "}}}


" API function to get popup id
function! hitspop#getpopupid() abort "{{{
  return get(s:, 'popup_id', '')
endfunction "}}}
