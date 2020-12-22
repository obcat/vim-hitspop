# vim-hitspop

Popup the number of search results.

![hitspop](https://i.gyazo.com/9d37d82d7ed411e45f4e461311e1f884.gif)

## Installation

Requires Vim 8.2.0896 or later.

If you use [vim-plug](https://github.com/junegunn/vim-plug), then add the following line to your vimrc:

```vim
Plug 'obcat/vim-hitspop'
```

You can use any other plugin manager.

## Usage

The `hlsearch` option must be turned on for this plugin to work:

```vim
set hlsearch
```

This is all you need to set up. If you run a search command like `/foo`, a popup will appear and show you the number of search results like `foo [3/7]`.

### How to clear the popup?

The `:nohlsearch` command, which stops the highlighting for the `hlsearch` option, also automatically clear the popup. To quickly execute this command, you may want to set up a key mapping in your vimrc. For example:

```vim
nnoremap <silent> <ESC><ESC> :<C-u>nohlsearch<CR>
```

## Customization

You can customize some features.

### Position

By default, popup is displayed at top right corner of current window.
If you want to display the popup, for example, at bottom left corner of current window, use this:

```vim
let g:hitspop_line_axis = 'winbot'
let g:hitspop_column_axis = 'winright'
```

![botright](https://user-images.githubusercontent.com/64692680/102859740-d628f880-446f-11eb-9f40-00b4fd97e434.png)

You can also specify other positions. Please see help file for more information.

### Highlight

The popup color can be changed setting the following highlight groups:

* `hitspopNormal` (default: links to `Pmenu`)
* `hitspopErrorMsg` (default: links to `Pmenu`)

Example:

![highlight ex](https://user-images.githubusercontent.com/64692680/102861798-851b0380-4473-11eb-9f32-8486cf78c822.png)


```vim
highlight link hitspopErrorMsg ErrorMsg
```

📝 I use [iceberg.vim](https://github.com/cocopon/iceberg.vim) for color scheme.

## License

MIT License.
