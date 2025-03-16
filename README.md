<!-- panvimdoc-ignore-start -->
<h1 align="center"> 📻 feed.nvim </h1>
<p align="center">
  <a href="https://github.com/neovim/neovim">
    <img alt="Static Badge" src="https://img.shields.io/badge/Neovim%200.10.0+-green.svg?style=for-the-badge&logo=neovim">
  </a>
  <a href="https://www.lua.org">
    <img alt="Static Badge" src="https://img.shields.io/badge/Lua-blue.svg?style=for-the-badge&logo=lua">
  </a>
  <a href="https://github.com/neo451/feed.nvim/releases.atom">
    <img src="https://img.shields.io/badge/rss-F88900?style=for-the-badge&logo=rss&logoColor=white">
  </a>
  <a href="https://github.com/neo451/feed.nvim/actions/workflows/mini-test.yml">
    <img alt="GitHub Actions Workflow Status" src="https://img.shields.io/github/actions/workflow/status/neo451/feed.nvim/mini-test.yml?style=for-the-badge">
  </a>
  <a href="https://luarocks.org/modules/neo451/feed.nvim">
    <img alt="LuaRocks" src="https://img.shields.io/luarocks/v/neo451/feed.nvim?style=for-the-badge">
  </a>
  <a href="https://discord.gg/N85Cd9P7w4">
    <img alt="Discord" src="https://img.shields.io/discord/1342870878794551356?style=for-the-badge&logo=discord">
  </a>
</p>

**feed.nvim** is a web feed reader in Neovim.

![image](https://github.com/user-attachments/assets/246a4e76-9ac8-4cb1-a351-141fe5038443)

![image](https://github.com/user-attachments/assets/e8f9c546-48f6-48d8-8cd6-a9b154df0625)

> [!WARNING]
> This project is young, expect breaking changes, and for now there's a nasty bug if you are on neovim stable [#125](https://github.com/neo451/feed.nvim/issues/125#issuecomment-2612966517), recommend to use nightly or wait for the coming release of 0.11
>
> other than that usage should be fun and smooth, go ahead and enjoy!

## 🌟 Features

- 🌲 Fast and reliable [rss](https://en.wikipedia.org/wiki/RSS)/[atom](<https://en.wikipedia.org/wiki/Atom_(web_standard)>)/[json feed](https://www.jsonfeed.org) feed parsing, powered by [tree-sitter](https://github.com/nvim-treesitter/nvim-treesitter)
- 📝 View entries as beautiful markdown powered by [pandoc](https://pandoc.org)
- 🏪 Lua database with no extra dependency
- 📚 Powerful entry searching by date, tag, feed, regex, and full text
- 📂 OPML support to import and export all your feeds and podcasts
- 🧡 [RSShub](https://github.com/DIYgod/RSSHub) integration to discover and track _everything_
- :octocat: Github integration to subscribe to the new commits/release of your favorite repo/plugin
- 📶 HTMX + libuv powered minimal web interface
- [ ] **WIP** 📡 support for popular feed sync services like [Tiny Tiny RSS](https://tt-rss.org/) and [Fresh RSS](https://github.com/FreshRSS/FreshRSS)

## 🚀 Installation

### Requirements

- Neovim 0.10+
- curl
- [pandoc](https://www.pandoc.org)
- tree-sitter-xml
- tree-sitter-html

### Optional Dependencies

- For feed greping:
  - [rg](https://github.com/BurntSushi/ripgrep)
- For interactive feed searching:
  - [snacks.picker](https://github.com/folke/snacks.nvim)
  - [mini.pick](https://github.com/echasnovski/mini.pick)
  - [fzf-lua](https://github.com/ibhagwan/fzf-lua)
  - [telescope.nvim](https://github.com/folke/snacks.nvim)
- For markdown rendering:
  - [render-markdown](https://github.com/MeanderingProgrammer/render-markdown.nvim)
  - [markview.nvim](https://github.com/OXY2DEV/markview.nvim)
- For image rendering:
  - [snacks.nvim](https://github.com/folke/snacks.nvim)

### Basic Installation

For [rocks.nvim](https://github.com/nvim-neorocks/rocks.nvim):

```vim
:Rocks install feed.nvim
```

For [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
return {
   "neo451/feed.nvim",
   cmd = "Feed",
   ---@module 'feed'
   ---@type feed.config
   opts = {},
}
```

### Further Steps

- Run `:checkhealth feed` to see your installation status
- Read [documentation](https://neo451.github.io/feed.nvim-docs) or `:h feed.txt`
- To troubleshoot without conflict from other plugins or you config, copy [minimal.lua](./minimal.lua) locally, and run `nvim --clean -u minimal.lua`

## ❤️ Related Projects

- [elfeed](https://github.com/skeeto/elfeed)
- [nvim-rss](https://github.com/EMPAT94/nvim-rss)
- [vnews](https://github.com/danchoi/vnews)
- [lua-feedparser](https://github.com/slact/lua-feedparser)
