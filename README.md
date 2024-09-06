<h1 align="center"> 📻 feed.nvim </h1>

[rss](https://en.wikipedia.org/wiki/RSS)/[atom](https://en.wikipedia.org/wiki/Atom_(web_standard))/[json](https://www.jsonfeed.orgt) feed reader in neovim, leveraging the modern neovim features and plugin system, like [tree-sitter](https://github.com/nvim-treesitter/nvim-treesitter), [telescope](https://github.com/nvim-telescope/telescope.nvim) and [render-markdown.nvim](https://github.com/tadmccorkle/markdown.nvim)

🚧 🚧 🚧 
This project is under heavy development, contributions are welcome!
🚧 🚧 🚧 

## Installation

### Minimal installation

> requires `nvim 0.10` and `curl` to be installed on your path.

Using [lazy.nvim](https://github.com/folke/lazy.nvim)

lazy.nvim:
```lua
{
    'noearc/feed.nvim',
    dependencies = { 
      'nvim-lua/plenary.nvim',
      "nvim-treesitter/nvim-treesitter",
    }
    opts = {}
}
```
```lua
-- somewhere in your config that sets up nvim-treesitter, add these three filetypes to the ensure_installed list:
require("nvim-treesitter.configs").setup({
   ensure_installed = { "xml", "html", "markdown" },
})
```

### Optional Dependencies

- For fuzzy finding your feeds and entries: get [telesope.nvim](https://github.com/nvim-telescope/telescope.nvim)
   - TODO: image
- For rendering entries beautifully in neovim: get [render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim)
   - TODO: image
- For nice UI for feed fetching progress, get [fidget.nvim](https://github.com/j-hui/fidget.nvim)
   - TODO: image
- For nice keymap hints, get [which-key.nvim](https://github.com/folke/which-key.nvim)
   - TODO: image

## Usage

### open feed.nvim
- Use `Feed` command to open the default index, there will be three main kind of index:
    - A `elfeed` style search buffer, everything is a flat list to be searched
    - A `telescope` picker, good for searching through all your database or search `by feed` **TODO**
    - A `tree` like menu, good for searching by feeds or tags **TODO**
- Use `Feed <Tab>` to find out more actions binded to `Feed` buffers

### searching
- Will support all the syntax of elfeed

## Customization

these are the defaults, no need to copy, only set the ones you wish to change
```lua
require("feed").setup{
   feeds = {
        { "https://neovim.io/news.xml", name = "neovim", tags = {"tech", "vim", "news"} -- a simple url pasted here is also fine
   }, -- this is where all your feeds go
   db_dir = "~/.local/share/nvim/feed",
   keymaps = {
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
      filetype = "markdown",
      modifiable = false,
   },
   search = {
      sort_order = "descending",
      update_hook = {},
      filter = "@6-months-ago +unread",
   },
   layout = {
      title = {
         right_justify = false,
         width = 70,
      },
      date = {
         format = "%Y-%m-%d",
         width = 10,
      },
   },
   split = "13split",
   colorscheme = "default", -- add your preferred colorscheme for reading here
}
```
## Feed management

TODO:

## RssHub integration

TODO:
