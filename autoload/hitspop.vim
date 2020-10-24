let s:save_cpo = &cpo
set cpo&vim


let s:show_search_word = get(g:, 'hitspop_show_search_word', 1)
let s:popup_zindex = get(g:, 'hitspop_popup_zindex', 50)
let s:popup_pos_bototom = get(g:, 'hitspop_popup_bottom', 0)

function! s:CreatePopup(line, col) abort
  if s:popup_pos_bototom == 0
    let popup_pos = 'topright'
  else
    let popup_pos = 'botright'
  endif
  let w:hitspop_popup_id = popup_create(s:GetContent(), #{
    \ line: a:line,
    \ col: a:col,
    \ pos: popup_pos,
    \ zindex: s:popup_zindex,
    \ padding: [0, 1, 0, 1],
    \ highlight: 'HitsPopPopup',
    \ wrap: 0,
    \ })
endfunction

function! s:DeletePopupIfExists() abort
  if s:PopupExists()
    call popup_clear(w:hitspop_popup_id)
    unlet w:hitspop_popup_id
  endif
endfunction

function! s:GetContent() abort
  let l:result = searchcount()
  if empty(l:result)
    return ''
  endif
  let search_word = s:show_search_word ? @/ . ' ' : ''
  if l:result.incomplete ==# 1
    return printf('%s[?/??]', search_word)
  elseif l:result.incomplete ==# 2
    if l:result.total > l:result.maxcount && l:result.current > l:result.maxcount
      return printf('%s[>%d/>%d]', search_word, l:result.current, l:result.total)
    elseif l:result.total > l:result.maxcount
      return printf('%s[%d/>%d]', search_word, l:result.current, l:result.total)
    endif
  endif
  return printf('%s[%d/%d]', search_word, l:result.current, l:result.total)
endfunction

function! s:HlIsOff() abort
  return !v:hlsearch
endfunction

function! s:MovePopup(line, col) abort
  call popup_move(w:hitspop_popup_id, #{line: a:line, col: a:col})
endfunction

function! s:PopupExists() abort
  return exists('w:hitspop_popup_id')
endfunction

function! s:UpdateContent() abort
  call popup_settext(w:hitspop_popup_id, s:GetContent())
endfunction

function! hitspop#main() abort
  if s:HlIsOff()
    call s:DeletePopupIfExists()
    return
  endif

  let l:winnr = winnr()
  let l:popup_col = win_screenpos(l:winnr)[1] + winwidth(l:winnr) - 1
  if s:popup_pos_bototom == 0
    let l:popup_line = win_screenpos(l:winnr)[0]
  else
    let l:popup_line = win_screenpos(l:winnr)[0] + winheight(l:winnr) -1
  endif

  if !s:PopupExists()
    call s:CreatePopup(l:popup_line, l:popup_col)
  else
    if !popup_locate(l:popup_line, l:popup_col)
      call s:MovePopup(l:popup_line, l:popup_col)
    endif
    call s:UpdateContent()
  endif
endfunction

function! hitspop#clean() abort
  call s:DeletePopupIfExists()
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
