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

local config = require "feed.config"
local db = require("feed.db").db(config.db_dir)
local render = require "feed.render"
local ut = require "feed.utils"
local format = require "feed.format"

local lines = {}
for i, entry in ipairs(db.index) do
   lines[i] = format.entry_name(entry)
end

local function feed(opts)
   pickers
      .new(opts, {
         prompt_title = "Feeds",
         previewer = previewers.new_buffer_previewer {
            --- TODO: attach highlighter! format content on disk to markdown
            define_preview = function(self, entry, _)
               local db_entry = db:address(db.index[entry.index])
               conf.buffer_previewer_maker(db_entry, self.state.bufnr, {
                  bufname = self.state.bufname,
                  winid = self.state.winid,
                  preview = opts.preview,
                  file_encoding = opts.file_encoding,
               })
            end,
         },
         finder = finders.new_table {
            results = lines,
         },
         attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
               actions.close(prompt_bufnr)
               local selection = action_state.get_selected_entry()
               local entry = db.index[selection.index]
               render.show(format.entry(entry, db:get(entry)), render.buf.entry[2], ut.highlight_entry)
            end)
            return true
         end,
         sorter = conf.generic_sorter(opts), -- TODO: sort by date?
      })
      :find()
end

return telescope.register_extension {
   setup = function(ext_config, usr_config) end,
   -- health = lp_health,
   exports = {
      feed = feed,
   },
}
