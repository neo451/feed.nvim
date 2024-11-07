return {
   { "nvim-lua/plenary.nvim", lazy = true },

   { "neo451/treedoc.nvim", lazy = true },
   {
      "neo451/feed.nvim",
      dependencies = {
         "nvim-treesitter/nvim-treesitter",
      },
      build = ":TSInstall xml html markdown",
      opts = {},
   },
}
