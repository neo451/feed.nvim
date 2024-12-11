local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local previewers = require "telescope.previewers"
local db = require "feed.db"
local ui = require "feed.ui"
local format = require "feed.ui.format"
local config = require "feed.config"
local make_entry = require "telescope.make_entry"

local function feed_search()
   local opts = config.integrations.telescope

   pickers
       .new(opts, {
          prompt_title = "Feeds",

          previewer = previewers.new_buffer_previewer {
             define_preview = function(self, entry, _)
                vim.schedule(function()
                   ui.show_entry { buf = self.state.bufnr, id = entry.value }
                   vim.api.nvim_set_option_value("wrap", true, { win = self.state.winid })
                   vim.api.nvim_set_option_value("conceallevel", 3, { win = self.state.winid })
                   vim.treesitter.start(self.state.bufnr, "markdown")
                end)
             end,
          },
          finder = finders.new_dynamic {
             fn = function(query)
                if query == "" or not query then -- TODO: move to query.lua
                   return {}
                end
                return ui.refresh { query = query, show = false }
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
                ui.show_entry { id = selection.value }
             end)
             actions.send_to_qflist:replace(function()
                actions.close(prompt_bufnr)
                ui.show_index()
                vim.schedule(function()
                   vim.cmd "ccl"
                end)
             end)
             return true
          end,
       })
       :find()
end

---TODO: get the current query

local feed_grep = function(opts)
   opts = opts or {}
   opts = vim.tbl_extend("force", opts, config.integrations.telescope)

   local finder = finders.new_async_job {
      command_generator = function(prompt)
         if not prompt or prompt == "" then
            return nil
         end

         local args = { "rg" }
         table.insert(args, "-e")
         table.insert(args, prompt)

         return vim.tbl_flatten {
            args,
            { "--color=never", "--no-heading", "--with-filename", "--line-number", "--column", "--smart-case" }

         }
      end,
      cwd = tostring(db.dir) .. "/data/",
      entry_makder = make_entry.gen_from_vimgrep(opts)
   }

   pickers.new(opts, {
      debounce = 1000, -- TODO:!
      prompt_title = "Feed Grep",
      finder = finder,
      previewer = previewers.new_buffer_previewer {
         title = "Feed Grep Preview",
         define_preview = function(self, entry, _)
            vim.print(vim.tbl_keys(_))
            local id = entry[1]:sub(1, 64)
            ui.show_entry { buf = self.state.bufnr, id = id }
            -- TODO: minimal opts for all searchers
            vim.api.nvim_set_option_value("wrap", true, { win = self.state.winid })
            vim.api.nvim_set_option_value("conceallevel", 3, { win = self.state.winid })
            vim.treesitter.start(self.state.bufnr, "markdown")
            -- TODO: jump the line that match query
         end,
      },

      attach_mappings = function(prompt_bufnr, _)
         actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            local id = selection[1]:sub(1, 64)
            ui.show_entry { id = id }
            -- jump_to_line(nil, render.state.entry_buf, selection)
         end)
         return true
      end,
      sorter = require "telescope.sorters".empty()
   }):find()
end

return {
   feed_search = feed_search,
   feed_grep = feed_grep,
}
