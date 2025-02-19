local M = {}

--- from plenary.nvim
local truncate = function(str, len, dots, direction)
   if vim.fn.strdisplaywidth(str) <= len then
      return str
   end
   local start = direction > 0 and 0 or str:len()
   local current = 0
   local result = ""
   local len_of_dots = vim.fn.strdisplaywidth(dots)
   local concat = function(a, b, dir)
      if dir > 0 then
         return a .. b
      else
         return b .. a
      end
   end
   while true do
      local part = vim.fn.strcharpart(str, start, 1)
      current = current + vim.fn.strdisplaywidth(part)
      if (current + len_of_dots) > len then
         result = concat(result, dots, direction)
         break
      end
      result = concat(result, part, direction)
      start = start + direction
   end
   return result
end

--- from plenary.nvim
---@param str string
---@param len integer
---@param dots string?
---@param direction integer?
M.truncate = function(str, len, dots, direction)
   str = tostring(str) -- We need to make sure its an actually a string and not a number
   dots = dots or "…"
   direction = direction or 1
   if direction ~= 0 then
      return truncate(str, len, dots, direction)
   else
      if vim.fn.strdisplaywidth(str) <= len then
         return str
      end
      local len1 = math.floor((len + vim.fn.strdisplaywidth(dots)) / 2)
      local s1 = truncate(str, len1, dots, 1)
      local len2 = len - vim.fn.strdisplaywidth(s1) + vim.fn.strdisplaywidth(dots)
      local s2 = truncate(str, len2, dots, -1)
      return s1 .. s2:sub(dots:len() + 1)
   end
end

--- from plenary.nvim
---@param str string
---@param width integer
---@param right_justify boolean
---@return string
M.align = function(str, width, right_justify)
   local str_len = vim.fn.strdisplaywidth(str)
   str = M.truncate(str, width)
   return right_justify and string.rep(" ", width - str_len) .. str or str .. string.rep(" ", width - str_len)
end

---@param str string
---@return string
M.unescape = function(str)
   return select(
      1,
      str:gsub("(\\%*", "*"):gsub("(\\[%[%]`%-!|#<>_()$.])", function(s)
         return s:sub(2)
      end)
   )
end

---@param str string
---@return string
M.capticalize = function(str)
   return str:sub(1, 1):upper() .. str:sub(2)
end

---@param str string
---@param sep string
---@return Iter
M.split = function(str, sep)
   return vim.iter(vim.split(str, sep))
      :map(function(v)
         return vim.trim(v)
      end)
      :filter(function(v)
         return v ~= ""
      end)
end

return M
