local ut = require "feed.utils"

local function append(str)
   vim.wo.winbar = vim.wo.winbar .. str
end

local function new_comp(name, str, width, grp, right)
   width = width or 0
   vim.g["feed_" .. name] = str
   append("%#" .. grp .. "#")
   append("%" .. (right and "" or "-") .. width + 1 .. "{g:feed_" .. name .. "}")
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

local function show_winbar()
   vim.wo.winbar = " "
   for _, v in ipairs(Config.layout) do
      if not v.right then
         new_comp(v[1], providers[v[1]](v), v.width, v.color, v.right)
      end
   end
   append "%="
   for _, v in ipairs(Config.layout) do
      if v.right then
         new_comp(v[1], providers[v[1]](v), v.width, v.color, v.right)
      end
   end
end

-- TODO: idea: show keymap hints at bottom like newsboat

return show_winbar
