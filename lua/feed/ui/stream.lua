local M = {}
local api = vim.api

---comment
---@param buf integer
---@return function|table
function M.new(buf)
   vim.bo[buf].modifiable = true
   local leftover = ""

   return function(data)
      if not api.nvim_buf_is_valid(buf) then
         return
      end
      leftover = leftover .. data
      local lines = {}
      local split_idx = 1

      while true do
         local newline_idx = leftover:find("\n", split_idx, true)
         if not newline_idx then
            break
         end

         table.insert(lines, leftover:sub(split_idx, newline_idx - 1))
         split_idx = newline_idx + 1
      end
      leftover = leftover:sub(split_idx)

      if #lines > 0 then
         api.nvim_buf_set_lines(buf, -1, -1, false, lines)
      end
   end
end

return M
