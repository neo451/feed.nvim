local ut = require "feed.utils"

---@param name any
---@param str any
---@param width any
---@param grp any
---@return string
local function new_comp(name, str, width, grp, right)
   local buf = {}
   width = width or #str
   vim.g["feed_" .. name] = str
   buf[#buf + 1] = ("%#" .. grp .. "#")
   buf[#buf + 1] = right and str or ut.align(str, width + 1)
   return table.concat(buf, "")
end

local providers = {}

setmetatable(providers, {
   __index = function(_, k)
      return function()
         return ut.capticalize(k)
      end
   end,
})

local DB = require "feed.db"
local Config = require 'feed.config'

providers.query = function()
   return vim.g.feed_current_query
end

providers.last_updated = function()
   return DB:lastUpdated() .. " "
end

-- TODO: needs to be auto updated
-- providers.progress = function()
--    current_index = current_index or 1
--    return ("[%d/%d]"):format(current_index, #on_display)
-- end

---@return string
local function show_winbar()
   local buf = { " " }
   for _, v in ipairs(Config.layout) do
      if not v.right then
         buf[#buf + 1] = new_comp(v[1], providers[v[1]](v), v.width, v.color, v.right)
      end
   end

   buf[#buf + 1] = "%="
   buf[#buf + 1] = "%<"

   for _, v in ipairs(Config.layout) do
      if v.right then
         buf[#buf + 1] = new_comp(v[1], providers[v[1]](v), v.width, v.color, v.right)
      end
   end
   return table.concat(buf, "")
end

-- TODO: idea: show keymap hints at bottom like newsboat

return show_winbar
