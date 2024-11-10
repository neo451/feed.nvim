local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
   error "This extension requires telescope.nvim"
end

local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local previewers = require "telescope.previewers"

local db = require("feed.db").new()
local render = require "feed.render"
local format = require "feed.format"
local config = require "feed.config"

local function feed()
   local opts = config.integrations.telescope or {}

   local lines = {}
   local idx_to_id = {}
   for id, entry in db:iter() do
      lines[#lines + 1] = format.entry_name(entry)
      idx_to_id[#idx_to_id + 1] = id
   end

   pickers
      .new(opts, {
         prompt_title = "Feeds",

         previewer = previewers.new_buffer_previewer {
            define_preview = function(self, entry, _)
               local db_entry = db.dir .. "/data/" .. idx_to_id[entry.index]
               conf.buffer_previewer_maker(db_entry, self.state.bufnr, {
                  bufname = self.state.bufname,
               })
               vim.api.nvim_set_option_value("wrap", true, { win = self.state.winid })
               vim.api.nvim_set_option_value("conceallevel", 3, { win = self.state.winid })
               vim.treesitter.start(self.state.bufnr, "markdown")
            end,
         },
         finder = finders.new_table {
            results = lines,
         },
         attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
               actions.close(prompt_bufnr)
               local selection = action_state.get_selected_entry()
               render.show_entry { row_idx = selection.index, untag = false }
            end)
            return true
         end,
         sorter = conf.generic_sorter(opts),
      })
      :find()
end

return telescope.register_extension {
   exports = {
      feed = feed,
   },
}
