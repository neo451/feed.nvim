vim.env.LAZY_STDPATH = ".repro"
load(vim.fn.system("curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"))()

local plugins = {
   {
      "neo451/feed.nvim",
      opts = {
         feeds = {
            "https://neovim.io/news.xml",
         },
      },
   },
   { "folke/snacks.nvim", lazy = true },
   { "j-hui/fidget.nvim", lazy = true },
   {
      "MeanderingProgrammer/render-markdown.nvim",
      dependencies = { "echasnovski/mini.icons" },
      opts = {},
   },
}

require("lazy.minit").repro({ spec = plugins })
