local M = {}

function M.append(str)
   vim.wo.winbar = vim.wo.winbar .. str
end

function M.new_comp(name, str, width, grp)
   width = width or 0
   vim.g["feed_" .. name] = str
   M.append("%#" .. grp .. "#")
   M.append("%-" .. width + 1 .. "{g:feed_" .. name .. "}")
end

return M
