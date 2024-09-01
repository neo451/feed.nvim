local M = {}

local xml = require "rss.xml"

---get lua table from opml
---@param path any
function M.parse_opml(path)
   path = vim.fn.expand(path)
   local str = table.concat(vim.fn.readfile(path))
   local ast = xml.parse(str)[2] -- discarded the xml decl tag, may need later
   return ast.body.outline, ast.head.title
end

-- local list, _ = M.parse_opml("~/Plugins/rss.nvim/lua/list.opml")
-- pp(list)

return M
