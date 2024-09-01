local M = {}

---render whole db in telescope
function M.show_telescope(opts)
   local pickers = require "telescope.pickers"
   local finders = require "telescope.finders"
   local conf = require("telescope.config").values
   local actions = require "telescope.actions"
   local action_state = require "telescope.actions.state"
   local db = require "rss.db"
   local render = require "rss.render"
   local ut = require "rss.utils"

   opts = opts or {}

   pickers
      .new(opts, {
         prompt_title = "Feeds",
         -- previewer = false,
         finder = finders.new_table {
            results = db.index,
         },
         attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
               actions.close(prompt_bufnr)
               local selection = action_state.get_selected_entry()
               render.show(render.format_entry(db[selection[1]]), render.buf.entry[2], ut.highlight_entry)
            end)
            return true
         end,
         sorter = conf.generic_sorter(opts), -- TODO: sort by date?
      })
      :find()
end

return M
