local M = {}

M = vim.tbl_extend("keep", M, require("feed.utils.shared"))
M = vim.tbl_extend("keep", M, require("feed.utils.url"))
M = vim.tbl_extend("keep", M, require("feed.utils.treesitter"))
M = vim.tbl_extend("keep", M, require("feed.utils.strings"))

return M
