return {
   { "gregorias/coop.nvim", lazy = true },
   {
      "neo451/feed.nvim",
      dependencies = {
         "nvim-treesitter/nvim-treesitter",
         main = "nvim-treesitter.configs",
         opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            table.insert(opts.ensure_installed, "xml")
            table.insert(opts.ensure_installed, "html")
            table.insert(opts.ensure_installed, "markdown")
            table.insert(opts.ensure_installed, "markdown_inline")
         end,
      },
      opts = {},
   },
}
