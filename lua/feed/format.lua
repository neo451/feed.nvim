local M = {}
local date = require "feed.parser.date"
local config = require "feed.config"
local treedoc = require "treedoc"
local ut = require "feed.utils"
local db = ut.require "feed.db"
-- local _treedoc = require "_treedoc"
local conv = require "treedoc.writers.markdown"

local align = ut.align

-- TODO: this whole module should be user definable

---@param tags string[]
---@return string
function M.tags(tags)
   if not tags then
      return "[unread]"
   end
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

---return a format info for an entry base on user config
---@param entry feed.entry
---@param comps table
---@return table
function M.get_entry_format(entry, comps)
   local acc_width = 0
   local res = {}
   for _, v in ipairs(comps) do
      local text = entry[v[1]] or ""
      if v[1] == "tags" then
         text = M.tags(entry.tags)
      elseif v[1] == "feed" then
         if db.feeds[entry.feed] then
            text = db.feeds[entry.feed].title
         else
            text = entry.feed
         end
      elseif v[1] == "date" then
         text = date.new_from.number(entry.time):format(config.date_format)
      end
      text = align(text, v.width, v.right_justify) .. " "
      res[#res + 1] = { color = v.color, width = acc_width, right_justify = v.right_justify, text = text }
      acc_width = acc_width + v.width + 1
   end
   return res
end

---@param entry feed.entry
---@return string
function M.entry_name(entry)
   local buf = {}
   local comps = M.get_entry_format(entry, {
      { "feed", width = 15 },
      { "tags", width = 15 },
      { "title", width = 80 },
   })
   for _, v in ipairs(comps) do
      buf[#buf + 1] = v.text
   end
   return table.concat(buf, " ")
end

return M
