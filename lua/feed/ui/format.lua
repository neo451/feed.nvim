local M = {}
local Config = require "feed.config"
local DB = require "feed.db"
local ut = require "feed.utils"

local align = ut.align
local tag2icon = Config.tag2icon

-- TODO: this whole module should be user definable

local function cleanup(str)
   return vim.trim(str:gsub("\n", ""))
end

---@param entry feed.entry
---@return string
function M.tags(entry)
   local tags = entry.tags
   if not tags then
      return tag2icon and "[👀]" or "[unread]"
   end
   if not tags["read"] then
      tags["unread"] = true
   end
   local taglist = vim.iter(vim.spairs(tags))
       :map(function(k)
          if tag2icon[k] then
             return tag2icon[k]
          end
          return k
       end)
       :totable()
   return "[" .. table.concat(taglist, ", ") .. "]"
end

---@param entry feed.entry
---@return string
---@return string
M.title = function(entry)
   return cleanup(entry.title), "FeedTitle"
end

---@param entry feed.entry
---@return string
---@return string
M.feed = function(entry)
   local feed = DB.feeds[entry.feed] and DB.feeds[entry.feed].title or entry.feed
   return cleanup(feed), "FeedTitle" -- FIX: for ttrss
end

---@param entry feed.entry
---@return string
---@return string
M.author = function(entry)
   local text
   if entry.author == "" then
      text = entry.feed
   else
      text = entry.author
   end
   return cleanup(text), "FeedTitle"
end

---@param entry feed.entry
---@return string
---@return string
M.link = function(entry)
   return entry.link, "FeedLink"
end

---@param entry feed.entry
---@return string
---@return string
M.date = function(entry)
   ---@diagnostic disable-next-line: return-type-mismatch
   return os.date(Config.date_format, entry.time), "FeedTitle"
end

---@param entry feed.entry
---@param comps table?
---@return string
M.entry = function(entry, comps)
   local buf = {}
   comps = comps or {
      { "feed",  width = 15 },
      { "tags",  width = 5 },
      { "title", width = 80 },
   }

   for _, v in ipairs(M.gen_format(entry, comps)) do
      buf[#buf + 1] = v.text
   end
   return table.concat(buf, " ")
end

---return a format info for an entry base on user config
---@param entry feed.entry
---@param comps table
---@return table
function M.gen_format(entry, comps)
   local acc_width = 0
   local res = {}
   for _, v in ipairs(comps) do
      local text = entry[v[1]] or ""
      if M[v[1]] then
         text = M[v[1]](entry)
      end
      v.width = v.width or #text
      v.width = v[1] == "title" and vim.api.nvim_win_get_width(0) - acc_width - 1 or v.width
      text = align(text, v.width, v.right_justify) .. " "
      res[#res + 1] = { color = v.color, width = acc_width, right_justify = v.right_justify, text = text }
      acc_width = acc_width + v.width + 1
   end
   return res
end

---return a NuiLine obj for an entry base on user config
---@param entry feed.entry
---@param comps table
---@return NuiLine
function M.gen_nui_line(entry, comps)
   local NuiLine = require "nui.line"
   local line = NuiLine()
   local acc_width = 0
   if not entry then
      return NuiLine()
   end
   for _, v in ipairs(comps) do
      local text = entry[v[1]] or ""
      if M[v[1]] then
         text = M[v[1]](entry)
      end
      local width = v[1] == "title" and vim.api.nvim_win_get_width(0) - acc_width - 1 or v.width
      line:append(align(text, width + 1, v.right_justify), v.color)
      acc_width = acc_width + v.width + 1
   end
   return line
end

return M
