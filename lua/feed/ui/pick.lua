local MiniPick = require "mini.pick"
local db = require "feed.db"
local render = require "feed.ui"
local format = require "feed.ui.format"

local lookup = {}
local ids = {}

for i, v in ipairs(db.index) do
   lookup[v[1]] = i
end

for _, v in ipairs(db.index) do
   ids[#ids + 1] = v[1]
end

local match_exact = function(_, _, query)
   if query == "" or not query then
      return {}
   end
   query = table.concat(query)
   render.on_display = db:filter(query)
   local ret = {}
   for _, v in ipairs(render.on_display) do
      if lookup[v] then
         table.insert(ret, lookup[v])
      end
   end
   return ret
end

local function feed_search()
   MiniPick.start {
      source = {
         items = ids,
         match = match_exact,
         show = function(buf_id, items_arr, _)
            local lines = vim.iter(items_arr)
               :map(function(id)
                  return format.entry(db[id])
               end)
               :totable()
            vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
         end,
         preview = function(buf_id, id)
            render.show_entry { buf = buf_id, id = id }
         end,
         choose = function(id)
            vim.cmd "q"
            render.show_entry { id = id }
         end,
      },
   }
end

--- TODO: rg-grep

return {
   feed_search = feed_search,
}
