vim.opt.rtp:append("deps/nvim-treesitter")
require("nvim-treesitter").install({ "html", "xml" }):wait(300000)
os.exit()
