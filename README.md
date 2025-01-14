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
  <a href="https://github.com/neo451/feed.nvim](https://github.com/neo451/feed.nvim/actions/workflows/mini-test.yml">
    <img alt="GitHub Actions Workflow Status" src="https://img.shields.io/github/actions/workflow/status/neo451/feed.nvim/mini-test.yml?style=for-the-badge">
  </a>
  <a href="https://luarocks.org/modules/neo451/feed.nvim">
    <img alt="LuaRocks" src="https://img.shields.io/luarocks/v/neo451/feed.nvim?style=for-the-badge">
  </a>
</p>

**feed.nvim** is a web feed reader in Neovim.

![image](https://github.com/user-attachments/assets/246a4e76-9ac8-4cb1-a351-141fe5038443)

![image](https://github.com/user-attachments/assets/e8f9c546-48f6-48d8-8cd6-a9b154df0625)


> [!WARNING]
> This project is young, expect breaking changes, but usage should be fun and seamless, go ahead and enjoy! 
>
> see [Roadmap](https://github.com/neo451/feed.nvim/wiki/Roadmap) for where this project goes.

## 🌟 Features

- 🌲 Fast and reliable [rss](https://en.wikipedia.org/wiki/RSS)/[atom](https://en.wikipedia.org/wiki/Atom_(web_standard))/[json feed](https://www.jsonfeed.org) feed parsing, powered by [tree-sitter](https://github.com/nvim-treesitter/nvim-treesitter)
- 📝 View entries as beautiful markdown powered by [pandoc](https://pandoc.org)
- 🏪 Lua database with no extra dependency
- 📚 Powerful entry searching by date, tag, feed, regex, and fulltext
- 📂 OPML support to import and export all your feeds and podcasts
- 🧡 [RSShub](https://github.com/DIYgod/RSSHub) integration to discover and track *everything*
- :octocat: Github integration to subscrbe to the new commits/release of your favorite repo/plugin
- [ ] Work as a feed server with a web interface
- [ ] Work as a feed client with support for services like [Tiny Tiny RSS](https://tt-rss.org/) and [Fresh RSS](https://github.com/FreshRSS/FreshRSS)

## 🚀 Installation

### Basic Installation

> [!NOTE]
> requires `nvim 0.10` and above
> 
> requires `pandoc` and `curl` to be installed on your path.

For [rocks.nvim](https://github.com/nvim-neorocks/rocks.nvim):

```
Rocks install feed.nvim
```

For [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{ "neo451/feed.nvim", cmd = "Feed" }
```

### Health Check

- run `:checkhealth feed` to see your installation status


## 🔖 Usage

- [Optional Integrations](https://github.com/neo451/feed.nvim/wiki/Integrations)
- [Usage Guide](https://github.com/neo451/feed.nvim/wiki/Usage-Guide)
- [Default Configs](https://github.com/neo451/feed.nvim/blob/5382d972e8ed9c2dc2b010fc86b32ddd54e75fde/lua/feed/config.lua#L15)
- [Recipes](https://github.com/neo451/feed.nvim/wiki/Recipes)

## ❤️ Related Projects

- [elfeed](https://github.com/skeeto/elfeed)
- [nvim-rss](https://github.com/EMPAT94/nvim-rss)
- [vnews](https://github.com/danchoi/vnews)
- [lua-feedparser](https://github.com/slact/lua-feedparser)
