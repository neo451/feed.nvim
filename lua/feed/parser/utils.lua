local M = {}

---@param thing table | string
---@param field string | integer
---@return string
function M.sensible(thing, field, fallback)
   if not thing then
      return fallback
   end
   if type(thing) == "table" then
      --- TODO: handle if list
      if vim.tbl_isempty(thing) then
         return fallback
      elseif type(thing[field]) == "string" then
         return thing[field]
      else
         return fallback
      end
   elseif type(thing) == "string" then
      if thing == "" then
         return fallback
      else
         return thing
      end
   else
      return fallback
   end
end

function M.sha(v)
   return vim.fn.sha256(v)
end

return M
