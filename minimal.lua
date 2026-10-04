vim.env.LAZY_STDPATH = ".repro"
load(vim.fn.system("curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"))()

local plugins = {
   {
      "neo451/feed.nvim",
      dependencies = {
         {
            "nvim-treesitter/nvim-treesitter",
            lazy = false,
            build = ":TSUpdate",
            config = function()
               require("nvim-treesitter").install({ "xml", "html", "markdown", "markdown_inline" })
            end,
         },
      },
      opts = {
         feeds = {
            "https://neovim.io/news.xml",
         },
      },
   },
   { "folke/snacks.nvim", lazy = false },
   {
      "MeanderingProgrammer/render-markdown.nvim",
      dependencies = { "echasnovski/mini.icons" },
      opts = {},
   },
}

require("lazy.minit").repro({ spec = plugins })
