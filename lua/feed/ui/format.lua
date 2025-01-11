local M = {}
local Config = require "feed.config"
local DB = require "feed.db"
local ut = require "feed.utils"
local strings = require "plenary.strings"

local align = ut.align
local icons = Config.icons

-- TODO: this whole module should be user definable

---@param str string
---@return string
local function cleanup(str)
   if not str then
      return ""
   end
   return vim.trim(str:gsub("\n", ""))
end

---@param id string
---@return string
function M.tags(id)
   local taglist = vim.iter(DB.tags)
       :fold({}, function(acc, tag, v)
          if type(v) == "table" and v[id] then
             if icons.enabled then
                acc[#acc + 1] = icons[tag] or tag
             else
                acc[#acc + 1] = tag
             end
          end
          return acc
       end)
   if vim.tbl_isempty(taglist) then
      if icons.enabled then
         taglist = { icons.unread }
      else
         taglist = { 'unread' }
      end
   end

   local tags_len

   for _, v in ipairs(Config.layout) do
      if v[1] == "tags" then
         tags_len = v.width - 2
      end
   end

   return "[" .. strings.truncate(table.concat(taglist, ", "), tags_len) .. "]"
end

---@param id string
---@return string
---@return string
M.title = function(id)
   local entry = DB[id]
   return cleanup(entry.title), "FeedTitle"
end

---@param id string
---@return string
---@return string
M.feed = function(id)
   local entry = DB[id]
   local feed = DB.feeds[entry.feed] and DB.feeds[entry.feed].title or entry.feed
   return cleanup(feed), "FeedTitle" -- FIX: for ttrss
end

---@param id string
---@return string
---@return string
M.author = function(id)
   ---@type feed.entry
   local entry = DB[id]
   local text
   if entry.author == "" then
      text = entry.feed
   else
      text = entry.author
   end
   return cleanup(text), "FeedTitle"
end

---@param id string
---@return string
---@return string
M.link = function(id)
   return DB[id].link, "FeedLink"
end

---@param id string
---@return string
---@return string
M.date = function(id)
   ---@diagnostic disable-next-line: return-type-mismatch
   return os.date(Config.date_format, DB[id].time), "FeedTitle"
end

---@param id string
---@param comps table?
---@return string
M.entry = function(id, comps)
   local buf = {}
   comps = comps or {
      { "feed",  width = 15 },
      { "tags",  width = 5 },
      { "title", width = 80 },
   }

   for _, v in ipairs(M.gen_format(id, comps)) do
      buf[#buf + 1] = v.text
   end
   return table.concat(buf, " ")
end

---return a format info for an entry base on user config
---@param id string
---@param comps table
---@return table
function M.gen_format(id, comps)
   local acc_width = 0
   local res = {}
   for _, v in ipairs(comps) do
      local text = DB[id][v[1]] or ""
      if M[v[1]] then
         text = M[v[1]](id)
      end
      text = align(text, v.width or #text, v.right_justify) .. " "
      res[#res + 1] = { color = v.color, width = acc_width, right_justify = v.right_justify, text = text }
      acc_width = acc_width + v.width + 1
   end
   return res
end

---return a NuiLine obj for an entry base on user config
---@param id string
---@param read boolean
---@return NuiLine
function M.entry_obj(id, read)
   local NuiLine = require "nui.line"
   local line = NuiLine()
   local acc_width = 0
   local entry = DB[id]
   if not entry then
      return NuiLine()
   end
   for _, v in ipairs(Config.layout) do
      local T = v[1]
      if not v.right then
         local text = entry[T] or ""
         if M[T] then
            text = M[T](id)
         end
         local width
         if T == "title" then
            width = #text
         else
            width = v.width
         end
         line:append(align(text, width + 1, v.right_justify), read and "FeedRead" or v.color)
         acc_width = acc_width + width + 1
      end
   end
   return line
end

return M
