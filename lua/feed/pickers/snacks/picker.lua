---@diagnostic disable: unresolved-require
local ui = require("feed.ui")

---@type any
local snacks_picker = require("snacks.picker")
local db = require("feed.db")

local function grep()
   snacks_picker.grep({
      dirs = {
         tostring(require("feed.db").dir / "data"),
      },
   })
end

local function search()
   snacks_picker.pick("feeds", {
      live = true,
      format = function(item)
         local id = item.value
         local line = ui.headline(id)
         return { { line } }
      end,
      preview = function(ctx)
         local id = ctx.item.value
         local buf = ctx.preview:scratch()
         vim.treesitter.start(buf, "markdown")
         ui.show_entry({ buf = buf, id = id })
      end,
      finder = function(_, ctx)
         local query = ctx.filter.search
         ui.state.entries = db:filter(query)
         return vim.tbl_map(function(line)
            return { value = line }
         end, ui.state.entries)
      end,
      confirm = function(picker, item)
         picker:close()
         local id = item.value
         vim.schedule(function()
            ui.show_entry({ id = id })
         end)
      end,
   })
end

return {
   feed_grep = grep,
   feed_search = search,
}
