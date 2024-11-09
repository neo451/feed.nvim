local M = {}
local date = require "feed.date"
local config = require "feed.config"
local treedoc = require "treedoc"
local db = require("feed.db").new()
-- local _treedoc = require "_treedoc"
local conv = require "treedoc.writers.markdown"
local ut = require "feed.utils"

local align = ut.align

---@param tags string[]
---@return string
function M.tags(tags)
   tags = vim.tbl_keys(tags)
   if #tags == 0 then
      return ""
   end
   local buffer = { "[" }
   for i, tag in pairs(tags) do
      buffer[#buffer + 1] = tag
      if i ~= #tags then
         buffer[#buffer + 1] = ", "
      end
   end
   buffer[#buffer + 1] = "]"
   return table.concat(buffer, "")
end

local function kv(k, v)
   return string.format("%s: %s", k, v)
end

---@param entry feed.entry
---@param feed_name string
---@return string
function M.entry(entry, feed_name)
   local lines = {}
   lines[#lines + 1] = entry.title and kv("Title", entry.title)
   lines[#lines + 1] = entry.time and kv("Date", date.new_from.number(entry.time))
   lines[#lines + 1] = entry.author and kv("Author", entry.author or entry.feed)
   lines[#lines + 1] = entry.feed and kv("Feed", feed_name)
   lines[#lines + 1] = entry.link and kv("Link", entry.link)
   lines[#lines + 1] = ""
   -- local md = _treedoc.write(_treedoc.read(entry.content, "html"), "markdown")
   if entry.content then
      local ok, md = pcall(conv, treedoc.parse("<html>" .. entry.content .. "</html>", { language = "html" })[1])
      if ok then
         for line in vim.gsplit(md, "\n") do
            lines[#lines + 1] = line
         end
      end
   end
   return table.concat(lines, "\n")
end

---@param entry feed.entry
---@return string
function M.entry_name(entry)
   local buf = {}
   local acc_width = 0

   for i, v in ipairs(config.layout) do
      local text = entry[v[1]] or ""
      if v[1] == "tags" then
         text = M.tags(entry.tags)
      elseif v[1] == "feed" then
         if db.feeds[entry.feed] then
            text = db.feeds[entry.feed].title
         else
            text = entry.feed
         end
      end
      if i == #config.layout then
         v.width = vim.api.nvim_win_get_width(0) - acc_width
      end
      if not text then
         vim.print(entry)
      end
      buf[#buf + 1] = align(text, v.width, v.right_justify)
      acc_width = acc_width + v.width
   end

   return table.concat(buf, " ")
end

return M
