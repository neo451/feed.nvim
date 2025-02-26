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
> This project is young, expect breaking changes, and for now there's a nasty bug if you are on neovim stable [#125](https://github.com/neo451/feed.nvim/issues/125#issuecomment-2612966517), recommand to use nightly or wait for the coming release of 0.11
>
> other than that usage should be fun and smooth, go ahead and enjoy!
>
> see [Roadmap](https://github.com/neo451/feed.nvim/wiki/Roadmap) for where this project goes.

## 🌟 Features

- 🌲 Fast and reliable [rss](https://en.wikipedia.org/wiki/RSS)/[atom](<https://en.wikipedia.org/wiki/Atom_(web_standard)>)/[json feed](https://www.jsonfeed.org) feed parsing, powered by [tree-sitter](https://github.com/nvim-treesitter/nvim-treesitter)
- 📝 View entries as beautiful markdown powered by [pandoc](https://pandoc.org)
- 🏪 Lua database with no extra dependency
- 📚 Powerful entry searching by date, tag, feed, regex, and fulltext
- 📂 OPML support to import and export all your feeds and podcasts
- 🧡 [RSShub](https://github.com/DIYgod/RSSHub) integration to discover and track _everything_
- :octocat: Github integration to subscrbe to the new commits/release of your favorite repo/plugin
- 📶 libuv powered feed server with a web interface
- 📡 support for popular feed sync services like [Tiny Tiny RSS](https://tt-rss.org/) and [Fresh RSS](https://github.com/FreshRSS/FreshRSS)

## 🚀 Installation

### Requirements

- neovim 0.10+
- curl
- [pandoc](https://www.pandoc.org)
- (optional) [rg](https://github.com/BurntSushi/ripgrep)

### Basic Installation

For [rocks.nvim](https://github.com/nvim-neorocks/rocks.nvim):

```vim
Rocks install feed.nvim
```

For [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{ "neo451/feed.nvim", cmd = "Feed" }
```

### Health Check

- run `:checkhealth feed` to see your installation status

<!-- panvimdoc-ignore-end -->

## Commands

### Sub commands and arguments

To execute actions available in the current context,
or give arguments to the command, use the following syntax:

Use `:Feed <Tab>`, `:Feed update_feed <Tab>` to get the completion

Use `:Feed<Enter>`, `:Feed update_feed<Enter>` to open menu and select

## Keymaps

Press `?` in to get hints.

### Index buffer

| action     | key      |
| ---------- | -------- |
| hints      | `?`      |
| dot_repeat | `.`      |
| undo       | `u`      |
| redo       | `<C-r>`  |
| entry      | `<CR>`   |
| split      | `<M-CR>` |
| browser    | `b`      |
| refresh    | `r`      |
| update     | `R`      |
| search     | `s`      |
| yank_url   | `y`      |
| untag      | `-`      |
| tag        | `+`      |
| quit       | `q`      |

### Entry buffer

| action   | key |
| -------- | --- |
| hints    | `?` |
| browser  | `b` |
| next     | `}` |
| prev     | `{` |
| full     | `f` |
| search   | `s` |
| untag    | `-` |
| tag      | `+` |
| urlview  | `r` |
| yank_url | `y` |
| quit     | `q` |

## Manage

### From lua

Pass your feeds as list of links and tags in setup

Use `Feed update` to update all

Use `Feed update_feed` to update one feed

```lua
require("feed").setup({
   feeds = {
      -- These two styles both work
      "https://neovim.io/news.xml",
      {
         "https://neovim.io/news.xml",
         name = "Neovim News",
         tags = { "tech", "news" }, -- tags given are inherited by all its entries
      },

      -- three link formats:
      "https://neovim.io/news.xml", -- Regular links
      "rsshub://rsshub://apnews/topics/apf-topnews" -- RSSHub links
      "neovim/neovim/releases" -- GitHub links
   },
})
```

### From OPML

Use `Feed load_opml` to import your OPML file

Use `Feed export_opml` to export your OPML file to load in other readers

### Link formats

#### Regular links

Must start with `http` or `https`

#### RSSHub links

RSSHub links are first class citizens, format is `rsshub://{route}`

`rsshub://{route}` will be resolved when fetching according to your config

Discover available `{route}` in [RSSHub documentation](https://docs.rsshub.app/routes/popular)
`rsshub://apnews/topics/apf-topnews` will be resolved to `https://rsshub.app/apnews/topics/apf-topnews` by default

Config example:

```lua
require("feed").setup({
   rsshub = {
      instance = "127.0.0.1:1200", -- or any public instance listed here https://rsshub.netlify.app/instances
      export = "https://rsshub.app", -- used in export_opml
   },
})
```

#### GitHub links

GitHub user/repo links are also first class citizens,format is `[github://]{user/repo}[{/releases|/commits}]`, so following four all work:

- `neo451/feed.nvim`
- `github://neo451/feed.nvim`
- `neo451/feed.nvim/releases`
- `github://neo451/feed.nvim/releases`

For now it defaults to subscribing to the commits

So first two is resolved into <https://github.com/neo451/feed.nvim/commits.atom>

Latter two is resolved into <https://github.com/neo451/feed.nvim/releases.atom>

## Search

- use `Feed search` to filter your feeds
- you can also pass the query like `Feed =neovim +read`
- the default query when you open up the index buffer is `+unread @2-weeks-ago`

### Regex

- no modifier matches entry title or entry url
- `!` is negative match with entry title or url
- `=` is matching feed name and feed url
- `~` is not matching feed name and feed url
- these all respect your `ignorecase` option

### Tags

- `+` means `must_have`, searches entries' tags
- `-` means `must_not_have`, searches entries' tags

### Date

- `@` means `date`, searches entries' date
- `2015-8-10` searches only entries after the date
- `2-months-ago` searches only entries within two months from now
- `1-year-ago--6-months-ago` means entries in the period

### Limit

- `#` means `limit`, limits the number of entries

### Examples

- `+blog +unread -star @6-months-ago #10 zig !rust`

Only Shows 10 entries with tags blog and unread, without tag star, and are published within 6 month, making sure they have zig but not rust in the title.

- `@6-months-ago +unread`

Only show unread entries of the last six months. This is the default filter.

- `linu[xs] @1-year-old`

Only show entries about Linux or Linus from the last year.

- `-unread +youtube ##10`

Only show the most recent 10 previously-read entries tagged as youtube.

- `+unread !n\=vim`

Only show unread entries not having vim or nvim in the title or link.

- `+emacs =http://example.org/feed/`

Only show entries tagged as emacs from a specific feed.

### Grep

Use `Feed grep` to live grep all entries in your database,
requires `rg` and one of the search backends:

- `telescope`
- `fzf-lua`
- `mini.pick`

## Recipes

<details><summary>Change the highlight of the tags section and use emojis and mini.icons for tags</summary>

```lua
require("feed").setup({
   layout = {
      tags = {
         color = "String",
         format = function(id, db)
            local icons = {
               news = "📰",
               tech = "💻",
               movies = "🎬",
               games = "🎮",
               music = "🎵",
               podcast = "🎧",
               books = "📚",
               unread = "🆕",
               read = "✅",
               junk = "🚮",
               star = "⭐",
            }

            local get_icon = function(name)
               if icons[name] then
                  return icons[name]
               end
               local has_mini, MiniIcons = pcall(require, "mini.icons")
               if has_mini then
                  local icon = MiniIcons.get("filetype", name)
                  if icon then
                     return icon .. " "
                  end
               end
               return name
            end

            local tags = vim.tbl_map(get_icon, db:get_tags(id))

            return "[" .. table.concat(tags, ", ") .. "]"
         end,
      },
   },
})
```

</details>

<details><summary>Custom function & keymap for podcast and w3m</summary>

```lua
local function play_podcast()
   local link = require("feed").get_entry().link
   if link:find("mp3") then
      vim.ui.open(link)
   -- any other player like:
   -- vim.system({ "vlc.exe", link })
   else
      vim.notify("not a podcast episode")
   end
end

local function show_in_w3m()
   if not vim.fn.executable("w3m") then
      vim.notify("w3m not installed")
      return
   end
   local link = require("feed").get_entry().link
   local w3m = require("feed.ui.window").new({
      relative = "editor",
      col = math.floor(vim.o.columns * 0.1),
      row = math.floor(vim.o.lines * 0.1),
      width = math.floor(vim.o.columns * 0.8),
      height = math.floor(vim.o.lines * 0.8),
      border = "rounded",
      style = "minimal",
      title = "Feed w3m",
      zindex = 10,
   })
   vim.keymap.set({ "n", "t" }, "q", "<cmd>q<cr>", { silent = true, buffer = w3m.buf })
   vim.fn.jobstart({ "w3m", link }, { term = true })
   vim.cmd("startinsert")
end

require("feed").setup({
   keys = {
      index = {
         [play_podcast] = "p",
         [show_in_w3m] = "w",
      },
   },
})
```

</details>

<details><summary>Custom colorscheme only set when viewing feeds</summary>

```lua
local og_color

vim.api.nvim_create_autocmd("User", {
   pattern = "FeedShowIndex",
   callback = function()
      if not og_color then
         og_color = vim.g.colors_name
      end
      vim.cmd.colorscheme("kanagawa-lotus")
   end,
})

vim.api.nvim_create_autocmd("User", {
   pattern = "FeedQuitIndex",
   callback = function()
      vim.cmd.colorscheme(og_color)
   end,
})
```

</details>

## Lua API

:TODO:

## Custom Action

:TODO:

<!-- panvimdoc-ignore-start -->

## ❤️ Related Projects

- [elfeed](https://github.com/skeeto/elfeed)
- [nvim-rss](https://github.com/EMPAT94/nvim-rss)
- [vnews](https://github.com/danchoi/vnews)
- [lua-feedparser](https://github.com/slact/lua-feedparser)
<!-- panvimdoc-ignore-start -->

```

```
