return {
   { "pysan3/pathlib.nvim", lazy = true },
   { "gregorias/coop.nvim", lazy = true },
   {
      "neo451/feed.nvim",
      dependencies = {
         "nvim-treesitter/nvim-treesitter",
         opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            table.insert(opts.ensure_installed, "xml")
         end,
      },
      opts = {},
   },
}
