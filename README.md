<h1 align="center"> 📻 feed.nvim </h1>
<p align="center">
  <a href="https://github.com/neovim/neovim">
    <img alt="Static Badge" src="https://img.shields.io/badge/neovim-version?style=for-the-badge&logo=neovim&label=%3E%3D%200.10&color=green">
  </a>
  <a href="https://github.com/neo451/feed.nvim">
    <img alt="GitHub repo size" src="https://img.shields.io/github/repo-size/neo451/feed.nvim?style=for-the-badge&logo=hackthebox">
  </a>
  <a href="https://github.com/neo451/feed.nvim/actions/workflows/busted.yml">
  <img alt="GitHub Actions Workflow Status" src="https://img.shields.io/github/actions/workflow/status/neo451/feed.nvim/busted.yml?style=for-the-badge&label=TESTS&color=green">
  </a>
</p>

**feed.nvim** is a web feed reader in neovim, leveraging modern neovim features and plugin system

🚧 🚧 🚧

*This project is in beta, many features are incomplete, but is already useable for most feeds, trying out and contributions are welcome!*

*see [roadmap](https://github.com/neo451/feed.nvim/wiki/Roadmap) for where this project goes*

🚧 🚧 🚧

## 🌟 Features

- 🌲 reliable and fast [rss](https://en.wikipedia.org/wiki/RSS)/[atom](https://en.wikipedia.org/wiki/Atom_(web_standard))/[json feed](https://www.jsonfeed.org) parsing, powered by [tree-sitter](https://github.com/nvim-treesitter/nvim-treesitter)
- 📝 feeds converted to markdown/neorg for reading and storing
- 🏪 pure lua database with no extra dependency
- 📚 powerful filtering of feeds and entries, inspired by [elfeed](https://github.com/skeeto/elfeed)
- 📶 [RSSHub](https://github.com/DIYgod/RSSHub) integration to turn (almost) any link into a web feed

## 🚀 Installation

### Basic Installation

> requires `nvim 0.10` and `curl` to be installed on your path.

Using [rocks.nvim](https://github.com/nvim-neorocks/rocks.nvim):

```
Rocks install feed.nvim
```

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
return {
    'neo451/feed.nvim',
    dependencies = {
      'neo451/treedoc.nvim',
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

### Health Check

- run `:checkhealth feed` to see your installation status

### Optional Integrations

- see [wiki/Integrations](https://github.com/neo451/feed.nvim/wiki/Integrations)

## 🔖 Usage

### Basic Usage

- Use `Feed` command to open the default index, there are two main kinds of index:
  - The `elfeed` style search buffer, everything is a flat list to be searched
  - The `telescope` picker, good for searching through all your database or search `by feed`
- Use `Feed <Tab>` to find out more actions binded to `Feed` buffers

### Feed Management

- Use `Feed load_opml` to import your opml file
- Use `Feed export_opml` to export your opml file to load in other readers

### Feed Searching

1. DSL query

- *WIP*: Will support all the syntax of elfeed, for now see [elfeed](https://github.com/skeeto/elfeed/tree/master?tab=readme-ov-file#filter-syntax)'s description.
- use `s` in index buffer to filter your feeds, currently suports: regex, must_have(`+`), must_not_have(`-`), and date(`@`).

2. Live grep

- use `Feed grep` to use telescope's `live_grep` (requires `ripgrep`) to do fulltext search accross your database.

### RssHub Integration

- *To Be Implemented*

### Tiny Tiny Rss Integration

- *To Be Implemented*

## Customization

- these are the defaults, no need to copy, only set the ones you wish to change

```lua
require"feed".setup{
   ---@type string
   db_dir = vim.fn.stdpath "data" .. "/feed",
   ---@type string
   colorscheme = "morning",

   index = {
      ---@type table<string, string | function>
      keys = {
         ["<CR>"] = "show_entry",
         ["<M-CR>"] = "show_in_split",
         ["+"] = "tag",
         ["-"] = "untag",
         ["?"] = "which_key",
         s = "search",
         b = "show_in_browser",
         w = "show_in_w3m",
         r = "refresh",
         y = "link_to_clipboard",
         q = "quit_index",
      },
      ---@type table<string, any>
      opts = {
         conceallevel = 0,
         wrap = false,
         number = false,
         relativenumber = false,
         modifiable = false,
      },
   },

   entry = {
      ---@type table<string, string | function>
      keys = {
         ["<CR>"] = "show_entry",
         ["}"] = "show_next",
         ["{"] = "show_prev",
         ["?"] = "which_key",
         ["+"] = "tag",
         ["-"] = "untag",
         u = "urlview",
         gx = "open_url",
         q = "quit_entry",
      },
      ---@type table<string, any>
      opts = {
         conceallevel = 0,
         wrap = true,
         number = false,
         relativenumber = false,
         modifiable = false,
         filetype = "markdown",
      },
   },
   ---@type table<string, any>
   layout = {
      title = {
         right_justify = false,
         width = 80,
      },
      date = {
         format = "%Y-%m-%d",
         width = 10,
      },
      ---@type string
      split = "13split",
      header = "Hint: <M-CR> open in split | <CR> open | + add tag | - remove tag | ? help", -- To be implemented
   },

   search = {
      default_query = "@6-months-ago +unread",
   },

   ---@type feed.feed[]
   feeds = {},
   integrations = {}, -- To be implemented
}

```

## Related Projects

- [elfeed](https://github.com/skeeto/elfeed)
- [nvim-rss](https://github.com/EMPAT94/nvim-rss)
- [vnews](https://github.com/danchoi/vnews)
- [lua-feedparser](https://github.com/slact/lua-feedparser)
