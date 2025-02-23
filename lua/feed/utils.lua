local M = {}

M = vim.tbl_extend("keep", M, require("feed.utils.shared"))
M = vim.tbl_extend("keep", M, require("feed.utils.url"))
M = vim.tbl_extend("keep", M, require("feed.utils.treesitter"))
M = vim.tbl_extend("keep", M, require("feed.utils.strings"))

M.decode = function(str)
   if not str then
      return nil
   end
   return require("feed.lib.entities").decode(str)
end

return M
