local ut = require("feed.utils")
local db = require("feed.db")
local config = require("feed.config")
local state = require("feed.state")

local M = {}
local cmp = {}

function _G._feed_bar_component(name)
   return cmp[name]()
end

local layout = config.winbar
local hi_pattern = "%%#%s#%s%%*"

setmetatable(cmp, {
   __index = function(_, k)
      return function()
         local sect = layout[k]
         local width = type(sect.width) == "number" and sect.width or #k
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

---@return string
function M.show_winbar()
   local buf = {}
   for _, name in ipairs(layout.order) do
      if not layout[name] then
         buf[#buf + 1] = name
      else
         buf[#buf + 1] = "%{%v:lua._feed_bar_component('" .. name .. "')%}"
      end
   end
   return table.concat(buf, " ")
end

return M
