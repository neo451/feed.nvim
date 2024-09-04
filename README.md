# rss.nvim

rss reader in neovim, leveraging the modern plugin system, like [tree-sitter](https://github.com/nvim-treesitter/nvim-treesitter) [telescope](https://github.com/nvim-telescope/telescope.nvim) and [markdown.nvim](https://github.com/tadmccorkle/markdown.nvim), maybe even [image.nvim](), WIP

## Installation

### Minimal installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim)

lazy.nvim:
```lua
{
    'noearc/rss.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' }
    opts = {}
}
```
### Dependencies

- For fuzzy finding your feeds and entries: get [telesope.nvim](https://github.com/nvim-telescope/telescope.nvim)
    - TODO: image
- For rendering entries beautifully in neovim: get [render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim)
    - TODO: image

## Usage

### open rss.nvim
- Use `Rss` command to open the default index, there will be three main kind of index:
    - A `elfeed` style search buffer, everything is a flat list to be searched
    - A `telescope` picker, good for searching through all your database or search `by feed` **TODO**
    - A `tree` like menu, good for searching by feeds or tags **TODO**
- Use `Rss <Tab>` to find out more actions binded to `Rss` buffers

### searching
- Will support all the syntax of elfeed

## Customization

these are the defaults, no need to copy, only set the ones you wish to change
```lua
require("rss").setup{
   feeds = {
        { "https://neovim.io/news.xml", name = "neovim", tags = {"tech", "vim", "news"} -- a simple url pasted here is also fine
   }, -- this is where all your feeds go
   db_dir = "~/.local/share/nvim/rss",
   date_format = "%Y-%m-%d",
   ---@alias rss.keymap table<string, string | function>
   keymaps = {
      ---@type rss.keymap
      index = {
         show_entry = "<CR>",
         show_in_split = "<M-CR>",
         show_in_browser = "b",
         show_in_w3m = "w",
         link_to_clipboard = "y",
         quit_index = "q",
         tag = "+",
         untag = "-",
      },
      ---@type rss.keymap
      entry = {
         show_index = "q",
         show_next = "}",
         show_prev = "{",
      },
   },
   win_options = {
      conceallevel = 0,
      wrap = true,
   },
   buf_options = {
      filetype = "markdown", -- TODO: rss?
      modifiable = false,
   },
   search = {
      sort_order = "descending",
      update_hook = {},
      filter = "@6-months-ago +unread",
   },
   titles = {
      right_justify = false,
      max_length = 70,
   },
   split = "13split",
   colorscheme = "kanagawa-lotus",
}
```
## Feed management

TODO:
