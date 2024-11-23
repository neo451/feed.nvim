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

> [!WARNING]
> This project is young, things like database format is prune to breaking changes, but the parser and renderer can deal with most feeds you can find, if you just wanna do some simple reading, go ahead and enjoy! 
>
> see [Roadmap](https://github.com/neo451/feed.nvim/wiki/Roadmap) for where this project goes.

## 🌟 Features

- 🌲 fast and reliable [rss](https://en.wikipedia.org/wiki/RSS)/[atom](https://en.wikipedia.org/wiki/Atom_(web_standard))/[json feed](https://www.jsonfeed.org) feed parsing, powered by [tree-sitter](https://github.com/nvim-treesitter/nvim-treesitter)
- 📝 view entries as beautiful markdown
- 🏪 pure lua database with no extra dependency
- 📚 powerful filtering of feeds and entries, inspired by [elfeed](https://github.com/skeeto/elfeed)

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
return { "neo451/feed.nvim" }
```

For other package managers, you need to manually install `nvim-lua/plenary.nvim`, `pysan3/pathlib.nvim` and `MunifTanjim/nui.nvim`, plus tree-sitter parsers for `xml`, `html`, and optionally `markdown`.

### Health Check

- run `:checkhealth feed` to see your installation status

### Optional Integrations

- [Optional Integrations](https://github.com/neo451/feed.nvim/wiki/Integrations)

## 🔖 Usage

- [Usage Guide](https://github.com/neo451/feed.nvim/wiki/Usage-Guide)
- [Default Configs](https://github.com/neo451/feed.nvim/wiki/Default-Config)
- [Recipes](https://github.com/neo451/feed.nvim/wiki/Recipes)

## Related Projects

- [elfeed](https://github.com/skeeto/elfeed)
- [nvim-rss](https://github.com/EMPAT94/nvim-rss)
- [vnews](https://github.com/danchoi/vnews)
- [lua-feedparser](https://github.com/slact/lua-feedparser)
