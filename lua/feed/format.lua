local M = {}
local strings = require "plenary.strings"
local date = require "feed.date"
local config = require "feed.config"
local treedoc = require "treedoc"
local conv = require "treedoc.conv.markdown"

---porperly align, justify and trucate the title
---@param str string
---@param max_len integer
---@param right_justify boolean
---@return string
function M.title(str, max_len, right_justify)
   local len = strings.strdisplaywidth(str)
   if len < max_len then
      return strings.align_str(str, max_len, right_justify)
   else
      return strings.align_str(strings.truncate(str, max_len), max_len, right_justify)
   end
end

---@param tags string[]
---@return string
function M.tags(tags)
   tags = vim.tbl_keys(tags)
   if #tags == 0 then
      return ""
   end
   local buffer = { "(" }
   for i, tag in pairs(tags) do
      buffer[#buffer + 1] = tag
      if i ~= #tags then
         buffer[#buffer + 1] = ", "
      end
   end
   buffer[#buffer + 1] = ")"
   return table.concat(buffer, "")
end

local function kv(k, v)
   return string.format("%s: %s", k, v)
end

---@param entry feed.entry
---@return table
function M.entry(entry, content)
   local lines = {}
   lines[1] = kv("Title", entry.title)
   lines[2] = kv("Date", date.new_from_int(entry.time))
   lines[3] = kv("Author", entry.author or entry.feed)
   lines[4] = kv("Feed", entry.feed)
   lines[5] = kv("Link", entry.link)
   lines[6] = ""
   local md = conv(treedoc.parse("<html>" .. content .. "</html>", { language = "html" })[1])
   for line in vim.gsplit(md, "\n") do
      lines[#lines + 1] = line
   end
   return lines
end

---@param entry feed.entry
---@return string
function M.entry_name(entry)
   local format = "%s %s %s %s"
   -- vim.api.nvim_win_get_width(0) -- TODO: use this or related autocmd to truncate title
   return string.format(
      format,
      tostring(date.new_from_int(entry.time)), -- TODO: use layout width
      M.title(entry.title, config.layout.title.width, config.layout.title.right_justify),
      entry.feed,
      M.tags(entry.tags)
   )
end

return M
