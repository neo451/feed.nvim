return {
   { "MunifTanjim/nui.nvim", lazy = true },
   { "pysan3/pathlib.nvim", lazy = true },
   {
      "neo451/feed.nvim",
      dependencies = {
         "nvim-treesitter/nvim-treesitter",
      },
      opts = {},
   },
}
