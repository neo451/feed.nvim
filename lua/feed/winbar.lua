local M = {}

-- local date = require "feed.date"
-- local db = require("feed.db").new()
local render = require "feed.render"

-- -- local updated = function()
-- --    return date.new_from_int(db.feed.lastUpdated):format "%c"
-- -- end

local config = require "feed.config"

local providers = {}

setmetatable(providers, {
   __index = function(_, k)
      return function()
         return string.upper(k:sub(0, 1)) .. k:sub(2, -1)
      end
   end,
})

providers.query = function()
   return render.state.query
end

vim.g.feed_query = render.state.query

local function append(str)
   vim.wo.winbar = vim.wo.winbar .. str
end

local function comp(name, str, min, grp)
   vim.g["feed_" .. name] = str
   append("%#" .. grp .. "#")
   append("%-" .. min + 1 .. "." .. min + 1 .. "{g:feed_" .. name .. "}")
end

function M.render()
   for _, v in ipairs(config.layout) do
      comp(v[1], providers[v[1]](v), v.width, v.color)
   end
end

function M.clear()
   vim.wo.winbar = ""
end

return M
