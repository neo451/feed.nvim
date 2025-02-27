local M = {}
local Config = require("feed.config")
local ut = require("feed.utils")

---@param id string
---@param db feed.db
---@return string
function M.tags(id, db)
   local tags = db:get_tags(id)
   return "[" .. table.concat(tags, ", ") .. "]"
end

---@param id string
---@param db feed.db
---@return string
M.title = function(id, db)
   return db[id].title
end

---@param id string
---@param db feed.db
---@return string
M.feed = function(id, db)
   local feeds = db.feeds
   local entry = db[id]
   return feeds[entry.feed] and feeds[entry.feed].title or entry.feed
end

---@param id string
---@param db feed.db
---@return string
M.author = function(id, db)
   local entry = db[id]
   return entry.author and entry.author or M.feed(id, db)
end

---@param id string
---@param db feed.db
---@return string
M.link = function(id, db)
   return db[id].link
end

---@param id string
---@param db feed.db
---@return string
M.date = function(id, db)
   ---@diagnostic disable-next-line: return-type-mismatch
   return os.date(Config.date_format.short, db[id].time)
end

---return a formated line for an entry base on user config
---@param id string
---@param layout table
---@param db feed.db
---@return string
---@return { start: number, stop: number, color: string }[]
M.entry = function(id, layout, db)
   local entry = db[id]
   local acc, res = 0, {}
   local coords = {}

   for _, name in ipairs(layout.order) do
      local v = layout[name]
      local text = entry[name] or ""
      local f = v.format or M[name]
      text = f(id, db)
      local width = type(v.width) == "number" and v.width or vim.fn.strdisplaywidth(text)
      text = ut.align(text, width, v.right_justify) .. " "
      res[#res + 1] = text
      coords[#coords + 1] = {
         start = acc,
         stop = acc + width,
         color = v.color,
      }
      acc = acc + width + 1
   end
   return table.concat(res), coords
end

return M
