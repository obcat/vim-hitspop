# vim-hitspop

Popup the number of search results.

![hitspop](https://user-images.githubusercontent.com/64692680/96633749-82594080-1354-11eb-913d-6d837891d845.gif)

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
If you want to display the popup, for example, at bottom left corner of current window, then add this setting to your vimrc:

```vim
let g:hitspop_popup_position = #{
  \ line: 'winbot',
  \ col: 'winleft',
  \ }
```

You can also specify other positions. Please see help file for more information.


## License

MIT License.
