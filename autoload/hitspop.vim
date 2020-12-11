" Maintainer: obcat <obcat@icloud.com>
" License:    MIT License


let s:show_search_word = get(g:, 'hitspop_show_search_word', 1)
let s:popup_zindex = get(g:, 'hitspop_popup_zindex', 50)

let s:searchcount_options = #{
  \ maxcount: 0,
  \ timeout: 30,
  \ }


function! s:create_popup(line, col) abort
  let s:popup_id = popup_create(s:get_content(), #{
    \ line: a:line,
    \ col: a:col,
    \ pos: 'topright',
    \ zindex: s:popup_zindex,
    \ padding: [0, 1, 0, 1],
    \ highlight: 'HitsPopPopup',
    \ wrap: 0,
    \ callback: 's:unlet_popup_id',
    \ })
endfunction


function! s:delete_popup_if_exists() abort
  if s:popup_exists()
    call popup_close(s:popup_id)
  endif
endfunction


function! s:get_content() abort
  let result = searchcount(s:searchcount_options)
  if empty(result)
    return ''
  endif

  let search_word = s:show_search_word ? @/ . ' ' : ''

  if result.incomplete ==# 1
    return printf('%s[?/??]', search_word)
  endif

  return printf('%s[%d/%d]', search_word, result.current, result.total)
endfunction


function! s:hl_is_off() abort
  return !v:hlsearch
endfunction


function! s:move_popup(line, col) abort
  call popup_move(s:popup_id, #{line: a:line, col: a:col})
endfunction


function! s:popup_exists() abort
  return exists('s:popup_id')
endfunction


function! s:unlet_popup_id(id, result) abort
  unlet s:popup_id
endfunction


function! s:update_content() abort
  call popup_settext(s:popup_id, s:get_content())
endfunction


function! hitspop#main() abort
  if s:hl_is_off()
    call s:delete_popup_if_exists()
    return
  endif

  let [popup_line, popup_col] = win_screenpos(0)
  let popup_col += winwidth(0) - 1

  if !s:popup_exists()
    call s:create_popup(popup_line, popup_col)
  else
    let pos = popup_getpos(s:popup_id)

    if [popup_line, popup_col] != [pos.line, pos.col]
      call s:move_popup(popup_line, popup_col)
    endif

    call s:update_content()
  endif
endfunction


function! hitspop#clean() abort
  if win_gettype() ==# 'popup'
    return
  endif
  call s:delete_popup_if_exists()
endfunction
