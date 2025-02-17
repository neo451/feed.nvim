local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")
local db = require("feed.db")
local ui = require("feed.ui")
local format = require("feed.ui.format")
local config = require("feed.config")
local sorters = require("telescope.sorters")

local function feed_search()
   local opts = config.integrations.telescope

   pickers
      .new(opts, {
         prompt_title = "Feeds",

         previewer = previewers.new_buffer_previewer({
            define_preview = function(self, entry, _)
               vim.schedule(function()
                  ui.preview_entry({ buf = self.state.bufnr, id = entry.value })
                  local winid = self.state.winid
                  vim.wo[winid].spell = false
                  vim.wo[winid].conceallevel = 3
                  vim.wo[winid].wrap = true
                  vim.treesitter.start(self.state.bufnr, "markdown")
               end)
            end,
         }),
         finder = finders.new_dynamic({
            fn = function(query)
               if query == "" or not query then -- TODO: move to query.lua
                  return {}
               end
               return ui.refresh({ query = query, show = false })
            end,
            entry_maker = function(line)
               return {
                  value = line,
                  text = format.entry(line),
                  filename = tostring(db.dir / "data" / line),
                  display = function(entry)
                     return format.entry(entry.value)
                  end,
                  ordinal = line,
               }
            end,
         }),
         attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
               actions.close(prompt_bufnr)
               local selection = action_state.get_selected_entry()
               ui.show_entry({ id = selection.value })
            end)
            actions.send_to_qflist:replace(function()
               actions.close(prompt_bufnr)
               ui.show_index()
               vim.schedule(function()
                  vim.cmd("ccl")
               end)
            end)
            return true
         end,
      })
      :find()
end

local ns_previewer = vim.api.nvim_create_namespace("ns_previewer")

local jump_to_line = function(obj, entry)
   local bufnr, winid = obj.buf, obj.win
   pcall(vim.api.nvim_buf_clear_namespace, bufnr, ns_previewer, 0, -1)

   if entry.lnum and entry.lnum > 0 then
      local lnum, lnend = entry.lnum - 1, (entry.lnend or entry.lnum) - 1

      local col, colend = 0, -1
      if entry.col and entry.colend then
         col, colend = entry.col - 1, entry.colend - 1
      end

      for i = lnum, lnend do
         pcall(
            vim.api.nvim_buf_add_highlight,
            bufnr,
            ns_previewer,
            "TelescopePreviewLine",
            i,
            i == lnum and col or 0,
            i == lnend and colend or -1
         )
      end
      local middle_ln = math.floor(lnum + (lnend - lnum) / 2)
      pcall(vim.api.nvim_win_set_cursor, winid, { middle_ln + 1, 0 })
      vim.api.nvim_buf_call(bufnr, function()
         vim.cmd("norm! zz")
      end)
   end
end

local feed_grep = function(opts)
   opts = opts or {}
   opts = {
      prompt_title = "Feed Grep",
      attach_mappings = function(prompt_bufnr, _)
         actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            ui.show_entry({ id = selection.filename })
            jump_to_line(ui.state.entry, selection)
         end)
         return true
      end,
      sorter = sorters.get_fzy_sorter(),
      cwd = tostring(db.dir / "data"),
   }
   opts = vim.tbl_extend("force", opts, config.integrations.telescope)
   require("telescope.builtin").live_grep(opts)
end

return {
   feed_search = feed_search,
   feed_grep = feed_grep,
}
