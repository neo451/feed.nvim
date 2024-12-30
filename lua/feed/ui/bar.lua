local ut = require "feed.utils"
local DB = require "feed.db"
local Config = require 'feed.config'

local M = {}
local cmp = {}

function _G._feed_bar_component(name)
   return cmp[name]()
end

local name2width, name2hl = {}, {}

for _, v in ipairs(Config.layout) do
   name2width[v[1]] = v.width
end

for _, v in ipairs(Config.layout) do
   name2hl[v[1]] = v.color
end

local hi_pattern = '%%#%s#%s%%*'

setmetatable(cmp, {
   __index = function(_, k)
      return function()
         local width = name2width[k] or #k
         local color = name2hl[k]
         return hi_pattern:format(color, ut.align(ut.capticalize(k), width + 1))
      end
   end,
})

cmp.query = function()
   return hi_pattern:format(name2hl["query"], vim.g.feed_current_query)
end

cmp.last_updated = function()
   return hi_pattern:format(name2hl["last_updated"], DB:lastUpdated())
end

cmp.progress = function()
   local count = vim.api.nvim_buf_line_count(0) - 1
   local cur = math.min(count, vim.api.nvim_win_get_cursor(0)[1])
   return hi_pattern:format("FeedRead", ("[%d/%d]"):format(cur, count))
end

---@return string
function M.show_winbar()
   local buf = { Config.layout.padding.enabled and " " or "" }
   for _, v in ipairs(Config.layout) do
      if not v.right then
         buf[#buf + 1] = "%{%v:lua._feed_bar_component('" .. v[1] .. "')%}"
      end
   end

   buf[#buf + 1] = "%=%<"

   local right = {}
   for _, v in ipairs(Config.layout) do
      if v.right then
         right[#right + 1] = "%{%v:lua._feed_bar_component('" .. v[1] .. "')%}"
      end
   end

   table.insert(buf, table.concat(right, " "))
   return table.concat(buf, "")
end

---@return string
function M.show_keyhints()
   local buf = {}
   for rhs, lhs in vim.spairs(Config.keys.entry) do
      buf[#buf + 1] = ("%s:%s"):format(lhs, ut.capticalize((rhs)))
   end

   return (Config.layout.padding.enabled and " " or "") .. "%#FeedRead#" .. table.concat(buf, "   ") .. "%<"
end

return M
