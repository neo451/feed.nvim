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
local ut = require "feed.utils"
local db = ut.require "feed.db"
local render = require "feed.ui"
local format = require "feed.ui.format"
local config = require "feed.config"
local cmds = require "feed.commands"

local function feed()
   cmds._register_autocmds()

   local opts = config.integrations.telescope or {}

   pickers
      .new(opts, {
         prompt_title = "Feeds",

         previewer = previewers.new_buffer_previewer {
            define_preview = function(self, entry, _)
               render.show_entry { buf = self.state.bufnr, id = entry.value, untag = false }
               vim.api.nvim_set_option_value("wrap", true, { win = self.state.winid })
               vim.api.nvim_set_option_value("conceallevel", 3, { win = self.state.winid })
               vim.treesitter.start(self.state.bufnr, "markdown")
            end,
         },
         finder = finders.new_dynamic {
            fn = function(query)
               if query == "" or not query then
                  return {}
               end
               render.on_display = db:filter(query)
               return render.on_display
            end,
            entry_maker = function(line)
               return {
                  value = line,
                  text = format.entry(db[line]),
                  filename = db.dir .. "/data/" .. line,
                  display = function(entry)
                     return format.entry(db[entry.value])
                  end,
                  ordinal = line,
               }
            end,
         },
         attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
               actions.close(prompt_bufnr)
               local selection = action_state.get_selected_entry()
               render.entry = vim.api.nvim_create_buf(false, true)
               render.show_entry { id = selection.value }
            end)
            actions.send_to_qflist:replace(function()
               actions.close(prompt_bufnr)
               render.show_index { refresh = true }
               vim.cmd "bd"
            end)
            return true
         end,
      })
      :find()
end

return telescope.register_extension {
   exports = {
      feed = feed,
   },
}
