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

### Health Check

- run `:checkhealth feed` to see your installation status

### Optional Integrations

*these integrations are very immature and are not the priority of development, but they are really cool for sure. these are just some suggestions, contributions are welcome!*

- For fuzzy finding your feeds and entries: get [telesope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- For rendering entries beautifully in neovim: get [render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim)
- For more browser-like reading: get [w3m.vim](https://github.com/yuratomo/w3m.vim)
- For nice keymap hints, get [which-key.nvim](https://github.com/folke/which-key.nvim)

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

- *To Be Implemented*

- Will support all the syntax of elfeed

### RssHub Integration

- *To Be Implemented*

### Tiny Tiny Rss Integration

- *To Be Implemented*

## Customization

- these are the defaults, no need to copy, only set the ones you wish to change

```lua
require"feed".setup{
   ---@type string
   db_dir = "~/.local/share/nvim/feed",
   ---@type { index : table<string, string | function>, entry : table<string, string | function> }
   keymaps = {
      index = {
         ["<CR>"] = "show_entry",
         ["<M-CR>"] = "show_in_split",
         ["+"] = "tag",
         ["-"] = "untag",
         ["?"] = "which_key",
         b = "show_in_browser",
         w = "show_in_w3m",
         r = "refresh",
         y = "link_to_clipboard",
         q = "quit_index",
      },
      entry = {
         ["}"] = "show_next",
         ["{"] = "show_prev",
         ["?"] = "which_key",
         u = "urlview",
         q = "quite_entry",
      },
   },
   ---@type table<string, any>
   win_options = {
      conceallevel = 0,
      wrap = true,
   },
   ---@type table<string, any>
   buf_options = {
      filetype = "markdown", -- TODO: FeedBuffer?
      modifiable = false,
   },
   ---@type table<string, any>
   search = {
      sort_order = "descending",
      update_hook = {},
      filter = "@6-months-ago +unread",
   },
   ---@type table<string, any>
   layout = {
      title = {
         right_justify = false,
         width = 70,
      },
      date = {
         format = "%Y-%m-%d",
         width = 10,
      },
      ---@type string
      split = "13split",
   },
   ---@type string
   colorscheme = "morning",

   ---@type feed.feed[]
   feeds = {},

   ---@type boolean
   zenmode = false,
}
```

## Related Projects

- [elfeed](https://github.com/skeeto/elfeed)
- [nvim-rss](https://github.com/EMPAT94/nvim-rss)
- [vnews](https://github.com/danchoi/vnews)
- [lua-feedparser](https://github.com/slact/lua-feedparser)
