local ut = require("feed.utils")
local db = require("feed.db")
local config = require("feed.config")
local state = require("feed.ui.state")

local M = {}
local cmp = {}

function _G._feed_bar_component(name)
   return cmp[name]()
end

local layout = config.layout
local hi_pattern = "%%#%s#%s%%*"

setmetatable(cmp, {
   __index = function(_, k)
      return function()
         local width = layout[k].width or #k
         local color = layout[k].color
         return hi_pattern:format(color, ut.align(ut.capticalize(k), width))
      end
   end,
})

cmp.query = function()
   return hi_pattern:format(layout["query"].color, vim.trim(state.query))
end

cmp.last_updated = function()
   return hi_pattern:format(layout["last_updated"].color, db:last_updated())
end

-- cmp.progress = function()
--    local count = vim.api.nvim_buf_line_count(0) - 1
--    local cur = math.min(count, vim.api.nvim_win_get_cursor(0)[1])
--    return hi_pattern:format("FeedRead", ("[%d/%d]"):format(cur, count))
-- end
--
---@return string
function M.show_winbar()
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

return M
