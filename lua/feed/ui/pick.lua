local MiniPick = require "mini.pick"
local ui = require "feed.ui"
local db = require "feed.db"
local format = require "feed.ui.format"
local config = require "feed.config"

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
            return format.entry(db[id])
         end)
         :totable()
      vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
   end

   MiniPick.start {
      source = {
         items = ids,
         match = match,
         show = show,
         preview = function(buf_id, id)
            ui.show_entry { buf = buf_id, id = id }
            local win = vim.api.nvim_get_current_win()
            for key, value in pairs(config.options.entry) do
               pcall(vim.api.nvim_set_option_value, key, value, { buf = buf_id })
               pcall(vim.api.nvim_set_option_value, key, value, { win = win })
               vim.treesitter.start(buf_id, "markdown")
            end
         end,
         choose = function(id)
            vim.cmd "q"
            ui.show_entry { id = id }
         end,
      },
   }
end

--- TODO: rg-grep

return {
   feed_search = feed_search,
}
