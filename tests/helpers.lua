local M = {}

local looks_like_url = require("feed.utils").looks_like_url

local dir = vim.uv.cwd()
local data_dir = dir .. "/data"

function M.readfile(path, prefix)
   prefix = prefix or data_dir
   local fp = vim.fs.joinpath(prefix, path)
   local str = vim.fn.readfile(fp)
   return table.concat(str)
end

function M.is_url(v)
   assert(looks_like_url(v))
end

-- local src = [[
-- Expect:      not bozo and feed['title'] == 'Example Atom'
-- ]]
local src2 = [[
Expect:      not bozo and entries[0]['author_detail']['email'] == 'me@example.com'
]]

function M.extract_test(str)
   local case = str:match("not bozo and (%C+)")
   if case:sub(1, 4) == "feed" then
      local k, v = case:match("feed%['(%w+)'%] == '(.+)'")
      return { [k] = v }
      -- TODO:
      -- elseif case:sub(1, 7) == "entries" then
      -- local k, v = case:match "entries%[0%]%['(%w+)'%] == '(.+)'"
      -- print(k, v)
      -- return { [k] = v }
   end
end

vim.print(M.extract_test(src2))

return M
