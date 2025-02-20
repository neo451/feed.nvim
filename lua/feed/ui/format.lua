local M = {}
local Config = require("feed.config")
local ut = require("feed.utils")

local align = ut.align
local icons = Config.icons

---@param str string
---@return string
local function cleanup(str)
   if not str then
      return ""
   end
   return vim.trim(str:gsub("\n", ""))
end

---@param id string
---@param db feed.db
---@return string
function M.tags(id, db)
   db = db or require("feed.db")

   local acc = {}

   -- 1. auto tag no [read] as [unread]
   if not (db.tags.read and db.tags.read[id]) then
      acc = { "unread" }
   end

   -- 2. get tags from tags.lua
   for tag, tagees in pairs(db.tags) do
      if tagees[id] then
         acc[#acc + 1] = tag
      end
   end

   local tags_len

   for _, v in ipairs(Config.layout) do
      if v[1] == "tags" then
         tags_len = v.width - 2
      end
   end

   return "[" .. ut.truncate(table.concat(acc, ", "), tags_len) .. "]"
end

---@param id string
---@param db feed.db
---@return string
M.title = function(id, db)
   db = db or require("feed.db")
   local entry = db[id]
   return cleanup(entry.title)
end

---@param id string
---@param db feed.db
---@return string
M.feed = function(id, db)
   db = db or require("feed.db")
   local feeds = db.feeds
   local entry = db[id]
   local feed = feeds[entry.feed] and feeds[entry.feed].title or entry.feed
   return cleanup(feed) -- FIX: for ttrss
end

---@param id string
---@param db feed.db
---@return string
M.author = function(id)
   db = db or require("feed.db")
   ---@type feed.entry
   local entry = db[id]
   local text
   if entry.author == "" then
      text = entry.feed
   else
      text = entry.author
   end
   return cleanup(text)
end

---@param id string
---@param db feed.db
---@return string
M.link = function(id, db)
   db = db or require("feed.db")
   return db[id].link
end

---@param id string
---@param db feed.db
---@return string
M.date = function(id, db)
   db = db or require("feed.db")
   ---@diagnostic disable-next-line: return-type-mismatch
   return os.date(Config.date_format.short, db[id].time)
end

---return a formated line for an entry base on user config
---@param id string
---@param comps table
---@param db feed.db
---@return string
M.entry = function(id, comps, db)
   db = db or require("feed.db")
   local entry = db[id]
   if not entry then
      return ""
   end

   comps = comps
      or {
         { "feed", width = 20 },
         { "tags", width = 20 },
         { "title", width = math.huge },
      }
   local acc = 0
   local res = {}

   for _, v in ipairs(comps) do
      local text = entry[v[1]] or ""
      if M[v[1]] then
         text = M[v[1]](id, db)
      end
      local width = v.width or #text
      text = align(text, width, v.right_justify) .. " "
      res[#res + 1] = text
      acc = acc + width
   end
   return table.concat(res)
end

return M
