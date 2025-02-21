local ut = require("feed.utils")
local DB = require("feed.db")
local Config = require("feed.config")
local state = require("feed.ui.state")

local M = {}
local cmp = {}

function _G._feed_bar_component(name)
   return cmp[name]()
end

local name2width, name2hl = {}, {}

for name, v in pairs(Config.layout) do
   name2width[name] = v.width
end

for name, v in pairs(Config.layout) do
   name2hl[name] = v.color
end

local hi_pattern = "%%#%s#%s%%*"

setmetatable(cmp, {
   __index = function(_, k)
      return function()
         local width = name2width[k] or #k
         local color = name2hl[k]
         return hi_pattern:format(color, ut.align(ut.capticalize(k), width))
      end
   end,
})

cmp.query = function()
   return hi_pattern:format(name2hl["query"], vim.trim(state.query))
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
   local layout = Config.layout
   local buf = {}

   for _, name in ipairs(layout.order) do
      buf[#buf + 1] = "%{%v:lua._feed_bar_component('" .. name .. "')%}"
   end

   buf[#buf + 1] = "%=%<"

   for _, name in ipairs(layout.winbar_right) do
      buf[#buf + 1] = "%{%v:lua._feed_bar_component('" .. name .. "')%}"
   end

   return table.concat(buf, " ")
end

---@return string
function M.show_keyhints()
   local buf = {}
   for rhs, lhs in vim.spairs(Config.keys.entry) do
      buf[#buf + 1] = ("%s:%s"):format(lhs, ut.capticalize(rhs))
   end

   return (Config.layout.padding.enabled and " " or "") .. "%#FeedRead#" .. table.concat(buf, "  ") .. "%<"
end

return M
