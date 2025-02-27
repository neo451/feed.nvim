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

---@param line integer
---@param display_start integer
---@param display_end integer
---@return number
---@return number
M.display_to_byte_range = function(line, display_start, display_end)
   local byte_start = 0
   local byte_end = 0
   local current_col = 0
   local current_byte = 0
   local len = #line

   local found_start = false
   local found_end = false

   while current_byte < len and (not found_start or not found_end) do
      local c = line:sub(current_byte + 1, current_byte + 1)
      local cp = c:byte()

      local bytes = 1
      if cp >= 0x80 then
         if cp >= 0xF0 then
            bytes = 4
         elseif cp >= 0xE0 then
            bytes = 3
         elseif cp >= 0xC0 then
            bytes = 2
         else
            bytes = 1
         end
      end

      bytes = math.min(bytes, len - current_byte)
      local char = line:sub(current_byte + 1, current_byte + bytes)
      local display_width = vim.fn.strdisplaywidth(char, current_col + 1)

      if not found_start and current_col + display_width > display_start then
         byte_start = current_byte
         found_start = true
      end

      if not found_end and current_col + display_width >= display_end then
         byte_end = current_byte + bytes
         found_end = true
      end

      current_col = current_col + display_width
      current_byte = current_byte + bytes
   end

   if not found_end then
      byte_end = current_byte
   end

   if byte_end < byte_start then
      byte_end = byte_start
   end

   return byte_start, byte_end
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
