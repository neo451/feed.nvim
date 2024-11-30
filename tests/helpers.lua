local M = {}

local dir = vim.uv.cwd()
local data_dir = dir .. "/data/"

function M.readfile(path, prefix)
   prefix = prefix or data_dir
   local str = vim.fn.readfile(prefix .. path)
   return table.concat(str)
end

return M
