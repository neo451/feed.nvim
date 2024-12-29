local ut = require "feed.utils"
local DB = require "feed.db"
local Config = require 'feed.config'

local M = {}

---@param str any
---@param width any
---@param grp any
---@return string
local function append(str, width, grp, right)
   local buf = {}
   width = width or #str
   buf[#buf + 1] = "%#" .. grp .. "#"
   buf[#buf + 1] = right and str or ut.align(str, width + 1)
   return table.concat(buf)
end

local providers = {}

setmetatable(providers, {
   __index = function(_, k)
      return function()
         return ut.capticalize(k)
      end
   end,
})

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
function M.show_winbar()
   local buf = { " " }
   for _, v in ipairs(Config.layout) do
      if not v.right then
         buf[#buf + 1] = append(providers[v[1]](v), v.width, v.color, v.right)
      end
   end

   buf[#buf + 1] = "%="
   buf[#buf + 1] = "%<"

   for _, v in ipairs(Config.layout) do
      if v.right then
         buf[#buf + 1] = append(providers[v[1]](v), v.width, v.color, v.right)
      end
   end
   return table.concat(buf, "")
end

---@return string
function M.show_keyhints()
   local buf = {}
   for rhs, lhs in vim.spairs(Config.keys.entry) do
      buf[#buf + 1] = ("%s:%s"):format(lhs, ut.capticalize((rhs)))
   end

   return " %#FeedRead#" .. table.concat(buf, "   ") .. "%<"
end

return M
