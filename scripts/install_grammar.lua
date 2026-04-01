vim.pack.add({ "https://github.com/nvim-treesitter/nvim-treesitter" })
require("nvim-treesitter")
   .install({
      "xml",
      "html",
      -- "markdown",
   })
   :wait(300000)
os.exit()
