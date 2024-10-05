<h1 align="center"> 📻 feed.nvim </h1>
<p align="center">
  <a href="https://github.com/neovim/neovim">
    <img alt="Static Badge" src="https://img.shields.io/badge/neovim-version?style=for-the-badge&logo=neovim&label=%3E%3D%200.10&color=green">
  </a>
  <a href="https://github.com/neo451/feed.nvim">
    <img alt="GitHub repo size" src="https://img.shields.io/github/repo-size/neo451/feed.nvim?style=for-the-badge&logo=hackthebox">
  </a>
</p>

**feed.nvim** is a web feed reader in neovim, leveraging modern neovim features and plugin system

🚧 🚧 🚧

This project is under heavy development, contributions are welcome!

🚧 🚧 🚧

## 🌟 Features

- 🌲 reliable and fast [rss](https://en.wikipedia.org/wiki/RSS)/[atom](https://en.wikipedia.org/wiki/Atom_(web_standard))/[json feed](https://www.jsonfeed.orgt) parsing, powered by [tree-sitter](https://github.com/nvim-treesitter/nvim-treesitter)
- 🏪 pure lua database with no extra dependency
- 📚 powerful filtering of feeds and entries, inspired by [elfeed](https://github.com/skeeto/elfeed)
- 📶 [RSSHub](https://github.com/DIYgod/RSSHub) integration to turn (almost) any link into a web feed

## 🚀 Installation

### Basic installation

> requires `nvim 0.10` and `curl` to be installed on your path.

Using [rocks.nvim](https://github.com/nvim-neorocks/rocks.nvim):

```
Rocks install feed.nvim
```

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
return {
    'noearc/feed.nvim',
    dependencies = { 
      'stevearc/conform.nvim',
      'j-hui/fidget.nvim',
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
    }
    opts = {}
}
```

```lua
-- somewhere in your config that sets up nvim-treesitter, add these three filetypes to the ensure_installed list:
require("nvim-treesitter.configs").setup {
   ensure_installed = { "xml", "html", "markdown" },
}
```

### Optional Dependencies

- For fuzzy finding your feeds and entries: get [telesope.nvim](https://github.com/nvim-telescope/telescope.nvim)
  - TODO: image
- For rendering entries beautifully in neovim: get [render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim)
  - TODO: image
- For nice keymap hints, get [which-key.nvim](https://github.com/folke/which-key.nvim)
  - TODO: image

## 🔖 Usage

### basic usage

- Use `Feed` command to open the default index, there will be three main kind of index:
  - The `elfeed` style search buffer, everything is a flat list to be searched
  - The `telescope` picker, good for searching through all your database or search `by feed`
- Use `Feed <Tab>` to find out more actions binded to `Feed` buffers

### feed management

- Use `Feed load_opml` to import your opml file
- Use `Feed export_opml` to export your opml file to load in other readers

### feed searching and filtering

- Will support all the syntax of elfeed

TODO:

### RssHub integration

TODO:

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
