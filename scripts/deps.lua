vim.cmd([[let &rtp.=','.getcwd()]])

vim.cmd("set rtp+=deps/mini.nvim")
require("mini.deps").setup({ path = { package = "deps/" } })

local add = MiniDeps.add

add({
   source = "nvim-treesitter/nvim-treesitter",
})
require("nvim-treesitter.configs").setup({
   ensure_installed = { "xml", "html", "markdown" },
})

add({
   source = "gregorias/coop.nvim",
})

os.exit()
