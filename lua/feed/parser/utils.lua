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

---TODO:

local function check_rsshub(_)
   return false -- TODO:
end

local function header_says_html(hdrs)
   for _, v in ipairs(hdrs) do
      local tag = v:lower()
      if tag:find "html" then -- TODO: maybe wrong, more formal
         return true
      end
   end
   return false
end

local function doctype_says_html(body)
   return body:find "<!DOCTYPE html>"
end

return M
