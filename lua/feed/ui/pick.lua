local MiniPick = require "mini.pick"
local ui = require "feed.ui"
local db = require "feed.db"
local format = require "feed.ui.format"
local Config = require "feed.config"
local ut = require "feed.utils"

local function feed_search()
   local lookup = {}
   local ids = {}

   for i, v in ipairs(db.index) do
      lookup[v[1]] = i
   end

   for _, v in ipairs(db.index) do
      ids[#ids + 1] = v[1]
   end

   local match = function(_, _, query)
      if query == "" or not query then
         return {}
      end
      query = table.concat(query)
      local on_display = ui.refresh { query = query, show = false }
      local ret = {}
      for _, v in ipairs(on_display) do
         if lookup[v] then
            table.insert(ret, lookup[v])
         end
      end
      return ret
   end
   local show = function(buf_id, items_arr, _)
      local lines = vim.iter(items_arr)
          :map(function(id)
             return format.entry(id, nil, db)
          end)
          :totable()
      vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
   end

   MiniPick.start {
      source = {
         items = ids,
         match = match,
         show = show,
         preview = function(buf, id)
            ui.preview_entry { buf = buf, id = id }
            local win = vim.api.nvim_get_current_win()
            ut.wo(win, Config.options.entry.wo)
            ut.bo(buf, Config.options.entry.bo)
         end,
         choose = function(id)
            vim.cmd "q"
            ui.show_entry { id = id }
         end,
      },
   }
end

local function feed_grep()
   MiniPick.builtin.grep_live({}, {
      source = {
         cwd = tostring(db.dir / "data"),
         show = function(buf_id, items_arr, _)
            for i, line in ipairs(items_arr) do
               local id = line:sub(1, 64)
               vim.api.nvim_buf_set_lines(buf_id, i - 1, i, false, { format.entry(id, nil, db) })
            end
         end,
      },
   })
end

return {
   feed_search = feed_search,
   feed_grep = feed_grep
}
