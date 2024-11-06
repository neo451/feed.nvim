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

*see [Roadmap](https://github.com/neo451/feed.nvim/wiki/Roadmap) for where this project goes*

🚧 🚧 🚧

## 🌟 Features

- 🌲 fast and reliable [rss](https://en.wikipedia.org/wiki/RSS)/[atom](https://en.wikipedia.org/wiki/Atom_(web_standard))/[json feed](https://www.jsonfeed.org) feed parsing, powered by [tree-sitter](https://github.com/nvim-treesitter/nvim-treesitter)
- 📝 view entries as beautiful markdown
- 🏪 pure lua database with no extra dependency
- 📚 powerful filtering of feeds and entries, inspired by [elfeed](https://github.com/skeeto/elfeed)

## 🚀 Installation

### Basic Installation

> requires `nvim 0.10` and `curl` to be installed on your path.

Using [rocks.nvim](https://github.com/nvim-neorocks/rocks.nvim):

```
Rocks install feed.nvim
```

Using [lazy.nvim](https://github.com/folke/lazy.nvim), with `luarocks` support:

```lua
return {　'neo451/feed.nvim',　opts = {}　}
```

```lua
-- somewhere in your config that sets up nvim-treesitter, add these three filetypes to the ensure_installed list:
require("nvim-treesitter.configs").setup {
   ensure_installed = { "xml", "html", "markdown" },
}
```

for others see: [Manual Installation](https://github.com/neo451/feed.nvim/wiki/Manual-installation)


### Health Check

- run `:checkhealth feed` to see your installation status

### Optional Integrations

- see [Optional Integrations](https://github.com/neo451/feed.nvim/wiki/Integrations)

## 🔖 Usage

- [Usage Guide](https://github.com/neo451/feed.nvim/wiki/Usage-Guide)
- [Default Configs](https://github.com/neo451/feed.nvim/wiki/Default-Config)
- [Recipes](https://github.com/neo451/feed.nvim/wiki/Recipes)

## Related Projects

- [elfeed](https://github.com/skeeto/elfeed)
- [nvim-rss](https://github.com/EMPAT94/nvim-rss)
- [vnews](https://github.com/danchoi/vnews)
- [lua-feedparser](https://github.com/slact/lua-feedparser)
