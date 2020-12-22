" Maintainer: obcat <obcat@icloud.com>
" License:    MIT License


let s:args = hitspop#_syntax_args()
let s:delimiter = '/'

for [s:groupname, s:pattern] in s:args
  exe 'syn match' s:groupname s:delimiter . escape(s:pattern, s:delimiter) . '\s*$' . s:delimiter
endfor
