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

local config = require "rss.config"
local db = require("rss.db").db(config.db_dir)
local render = require "rss.render"
local ut = require "rss.utils"
local date = require "rss.date"

---@param entry rss.entry
---@return string
local function entry_name(entry)
   local format = "%s %s %s %s"
   -- vim.api.nvim_win_get_width(0) -- TODO: use this or related autocmd to truncate title
   return string.format(
      format,
      tostring(date.new_from_int(entry.time)),
      -- tostring(date.new_from_entry(entry.pubDate)),
      ut.format_title(entry.title, config.max_title_length),
      entry.feed,
      ut.format_tags(entry.tags)
   )
end

local lines = {}
for i, entry in ipairs(db.index) do
   lines[i] = entry_name(entry)
end

---render whole db in telescope

local function rss(opts)
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
               render.show(render.format_entry(db.index[selection.index]), render.buf.entry[2], ut.highlight_entry)
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
      rss = rss,
   },
}
