let s:save_cpo = &cpo
set cpo&vim


let s:show_search_word = get(g:, 'hitspop_show_search_word', 1)
let s:popup_zindex = get(g:, 'hitspop_popup_zindex', 50)

let s:searchcount_options = #{
  \ maxcount: 0,
  \ timeout: 30,
  \ }


function! s:CreatePopup(line, col) abort
  let s:hitspop_popup_id = popup_create(s:GetContent(), #{
    \ line: a:line,
    \ col: a:col,
    \ pos: 'topright',
    \ zindex: s:popup_zindex,
    \ padding: [0, 1, 0, 1],
    \ highlight: 'HitsPopPopup',
    \ wrap: 0,
    \ callback: 's:UnletPopupID',
    \ })
endfunction


function! s:DeletePopupIfExists() abort
  if s:PopupExists()
    call popup_close(s:hitspop_popup_id)
  endif
endfunction


function! s:GetContent() abort
  let l:result = searchcount(s:searchcount_options)

  if empty(l:result)
    return ''
  endif

  let search_word = s:show_search_word ? @/ . ' ' : ''

  if l:result.incomplete ==# 1
    return printf('%s[?/??]', search_word)
  endif

  return printf('%s[%d/%d]', search_word, l:result.current, l:result.total)
endfunction


function! s:HlIsOff() abort
  return !v:hlsearch
endfunction


function! s:MovePopup(line, col) abort
  call popup_move(s:hitspop_popup_id, #{line: a:line, col: a:col})
endfunction


function! s:PopupExists() abort
  return exists('s:hitspop_popup_id')
endfunction


function! s:UnletPopupID(id, result) abort
  unlet s:hitspop_popup_id
endfunction


function! s:UpdateContent() abort
  call popup_settext(s:hitspop_popup_id, s:GetContent())
endfunction


function! hitspop#main() abort
  if s:HlIsOff()
    call s:DeletePopupIfExists()
    return
  endif

  let [l:popup_line, l:popup_col] = win_screenpos(0)
  let l:popup_col += winwidth(0) - 1

  if !s:PopupExists()
    call s:CreatePopup(l:popup_line, l:popup_col)
  else
    let l:pos = popup_getpos(s:hitspop_popup_id)

    if [l:popup_line, l:popup_col] != [l:pos.line, l:pos.col]
      call s:MovePopup(l:popup_line, l:popup_col)
    endif

    call s:UpdateContent()
  endif
endfunction


function! hitspop#clean() abort
  if win_gettype() ==# 'popup'
    return
  endif
  call s:DeletePopupIfExists()
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
