# vim-hitspop

Popup the number of search results.

![hitspop](https://user-images.githubusercontent.com/64692680/102915667-81b06800-44c5-11eb-8b53-e37eacc4e67b.gif)


## Installation

Requires Vim 8.2.0896 or later.

If you use [vim-plug](https://github.com/junegunn/vim-plug), then add the
following line to your vimrc:

```vim
Plug 'obcat/vim-hitspop'
```

You can use any other plugin manager.


## Usage

The `hlsearch` option must be turned on for this plugin to work:

```vim
set hlsearch
```

This is all you need to set up. If you run a search command like `/foo`,
a popup will appear and show you the number of search results like `foo  3 of 7`.

### Tips

When you stop highlighting, the popup will be closed automatically.

Highlighting can be stopped with the `nohlsearch` command.
To run this command quickly, you may want to set up the following map:


```vim
nnoremap <silent> <ESC><ESC> :<C-u>nohlsearch<CR>
```

You can also use the nohlsearch feature of
[is.vim](https://github.com/haya14busa/is.vim) plugin to stop highlighting
automatically. Please see the link for details.

To be precise, popup will be closed when one of the following occurs after
stopping highlighting:

* The cursor was moved.
* The time specified with `updatetime` option has elapsed.

The default value of `updatetime` is `4000`, i.e. 4 seconds. If you want to
close the popup as soon as possible after stopping highlighting, reduce the
value of this option. I suggest around 100ms:

```vim
set updatetime=100
```

Note that `updatetime` also controls the delay before Vim writes its swap file
(see `:h updatetime`).


## Customization

You can customize some features.


### Position

By default, popup is displayed at top right corner of current window.
If you want to display the popup, for example, at bottom left corner of current window, use this:

```vim
let g:hitspop_line_axis = 'winbot'
let g:hitspop_column_axis = 'winright'
```

![botright](https://user-images.githubusercontent.com/64692680/102915781-b3293380-44c5-11eb-9068-84fe2defe5fd.png)

You can also specify other positions. Please see help file for more information.


### Highlight

The popup color can be changed setting the following highlight groups:

* `hitspopNormal` (default: links to `Pmenu`)
* `hitspopErrorMsg` (default: links to `Pmenu`)

Example:

![highlight ex](https://user-images.githubusercontent.com/64692680/102916237-90e3e580-44c6-11eb-803d-6daa577bed98.png)

```vim
highlight link hitspopErrorMsg ErrorMsg
```

📝 I use [iceberg.vim](https://github.com/cocopon/iceberg.vim) for color scheme.


## License

MIT License.
