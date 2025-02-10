local M = {}
local Config = require("feed.config")
local ut = require("feed.utils")

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
function M.tags(id, db)
   local taglist = vim.iter(db.tags):fold({}, function(acc, tag, v)
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
         taglist = { "unread" }
      end
   end

   local tags_len

   for _, v in ipairs(Config.layout) do
      if v[1] == "tags" then
         tags_len = v.width - 2
      end
   end

   return "[" .. ut.truncate(table.concat(taglist, ", "), tags_len) .. "]"
end

---@param id string
---@return string
---@return string
M.title = function(id, db)
   local entry = db[id]
   return cleanup(entry.title), "FeedTitle"
end

---@param id string
---@return string
---@return string
M.feed = function(id, db)
   local entry = db[id]
   local feed = db.feeds[entry.feed] and db.feeds[entry.feed].title or entry.feed
   return cleanup(feed), "FeedTitle" -- FIX: for ttrss
end

---@param id string
---@return string
---@return string
M.author = function(id, db)
   ---@type feed.entry
   local entry = db[id]
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
M.link = function(id, db)
   return db[id].link, "FeedLink"
end

---@param id string
---@return string
---@return string
M.date = function(id, db)
   ---@diagnostic disable-next-line: return-type-mismatch
   return os.date(Config.date_format.short, db[id].time), "FeedTitle"
end

---return a formated line for an entry base on user config
---@param id string
---@param comps table
---@param db feed.db
---@return string
function M.entry(id, comps, db)
   local entry = db[id]
   if not entry then
      return ""
   end

   comps = comps
      or {
         { "feed", width = 20 },
         { "tags", width = 15 },
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
