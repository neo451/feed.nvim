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
local utils = require "telescope.utils"
local make_entry = require "telescope.make_entry"
local sorters = require "telescope.sorters"

local config = require "feed.config"
local db = require "feed.db"
local render = require "feed.render"
local format = require "feed.format"
render.prepare_bufs()

local Path = require "plenary.path"

-- Gets called only once to parse everything out for the vimgrep, after that looks up directly.
local parse_with_col = function(t)
   local _, _, filename, lnum, col, text = string.find(t.value, [[(..-):(%d+):(%d+):(.*)]])

   local ok
   ok, lnum = pcall(tonumber, lnum)
   if not ok then
      lnum = nil
   end

   ok, col = pcall(tonumber, col)
   if not ok then
      col = nil
   end

   t.filename = filename
   t.lnum = lnum
   t.col = col
   t.text = text

   return { filename, lnum, col, text }
end

local function gen_from_vimgrep(opts)
   opts = opts or {}

   local mt_vimgrep_entry
   local parse = parse_with_col

   local only_sort_text = opts.only_sort_text

   local execute_keys = {
      path = function(t)
         if Path:new(t.filename):is_absolute() then
            return t.filename, false
         else
            return Path:new({ t.cwd, t.filename }):absolute(), false
         end
      end,

      filename = function(t)
         return parse(t)[1], true
      end,

      lnum = function(t)
         return parse(t)[2], true
      end,

      col = function(t)
         return parse(t)[3], true
      end,

      text = function(t)
         return parse(t)[4], true
      end,
   }

   -- For text search only, the ordinal value is actually the text.
   if only_sort_text then
      execute_keys.ordinal = function(t)
         return t.text
      end
   end

   mt_vimgrep_entry = {
      cwd = utils.path_expand(opts.cwd or vim.loop.cwd()),

      display = function(entry)
         local sha1 = entry.filename:sub(6)
         for _, en in ipairs(db.index) do
            if en.id == sha1 then
               return format.entry_name(en)
            end
         end
      end,

      __index = function(t, k)
         -- local override = handle_entry_index(opts, t, k)
         -- if override then
         --    return override
         -- end

         local raw = rawget(mt_vimgrep_entry, k)
         if raw then
            return raw
         end

         local executor = rawget(execute_keys, k)
         if executor then
            local val, save = executor(t)
            if save then
               rawset(t, k, val)
            end
            return val
         end

         local lookup_keys = {
            value = 1,
            ordinal = 1,
         }
         return rawget(t, rawget(lookup_keys, k))
      end,
   }

   return function(line)
      return setmetatable({ line }, mt_vimgrep_entry)
   end
end

local flatten = function(t)
   return vim.iter(t):flatten():totable()
end

local has_rg_program = function(picker_name, program)
   if vim.fn.executable(program) == 1 then
      return true
   end

   return false
end

local ns_previewer = vim.api.nvim_create_namespace "feed.telescope"

local jump_to_line = function(win, bufnr, entry)
   pcall(vim.api.nvim_buf_clear_namespace, bufnr, ns_previewer, 0, -1)

   if entry.lnum and entry.lnum > 0 then
      local lnum, lnend = entry.lnum - 1, (entry.lnend or entry.lnum) - 1

      local col, colend = 0, -1
      if entry.col and entry.colend then
         col, colend = entry.col - 1, entry.colend - 1
      end

      for i = lnum, lnend do
         pcall(vim.api.nvim_buf_add_highlight, bufnr, ns_previewer, "TelescopePreviewLine", i, i == lnum and col or 0, i == lnend and colend or -1)
      end

      local middle_ln = math.floor(lnum + (lnend - lnum) / 2)
      pcall(vim.api.nvim_win_set_cursor, win or 0, { middle_ln + 1, 0 })
      vim.api.nvim_buf_call(bufnr, function()
         vim.cmd "norm! zz"
      end)
   end
end

local live_grep = function(opts)
   local vimgrep_arguments = opts.vimgrep_arguments or conf.vimgrep_arguments
   if not has_rg_program("live_grep", vimgrep_arguments[1]) then
      return
   end
   local search_dirs = opts.search_dirs
   if search_dirs then
      for i, path in ipairs(search_dirs) do
         search_dirs[i] = utils.path_expand(path)
      end
   end

   local additional_args = {}
   if opts.additional_args ~= nil then
      if type(opts.additional_args) == "function" then
         additional_args = opts.additional_args(opts)
      elseif type(opts.additional_args) == "table" then
         additional_args = opts.additional_args
      end
   end

   if opts.type_filter then
      additional_args[#additional_args + 1] = "--type=" .. opts.type_filter
   end

   if type(opts.glob_pattern) == "string" then
      additional_args[#additional_args + 1] = "--glob=" .. opts.glob_pattern
   elseif type(opts.glob_pattern) == "table" then
      for i = 1, #opts.glob_pattern do
         additional_args[#additional_args + 1] = "--glob=" .. opts.glob_pattern[i]
      end
   end

   if opts.file_encoding then
      additional_args[#additional_args + 1] = "--encoding=" .. opts.file_encoding
   end

   local args = flatten { vimgrep_arguments, additional_args }
   -- opts.__inverted, opts.__matches = opts_contain_invert(args)

   local live_grepper = finders.new_job(function(prompt)
      if not prompt or prompt == "" then
         return nil
      end

      local search_list = {}

      if search_dirs then
         search_list = search_dirs
      end

      return flatten { args, "--", prompt, search_list }
   end, opts.entry_maker or make_entry.gen_from_vimgrep(opts), opts.max_results, opts.cwd)

   pickers
      .new(opts, {
         prompt_title = "Feed Grep",
         finder = live_grepper,
         previewer = previewers.new_buffer_previewer {
            define_preview = function(self, entry, _)
               jump_to_line(self, self.state.bufnr, entry)

               local path = config.db_dir .. "/" .. entry.filename
               vim.api.nvim_set_option_value("wrap", true, { win = self.state.winid })
               vim.api.nvim_set_option_value("conceallevel", 3, { win = self.state.winid })
               vim.treesitter.start(self.state.bufnr, "markdown")

               conf.buffer_previewer_maker(path, self.state.bufnr, {
                  bufname = self.state.bufname,
                  callback = function()
                     vim.api.nvim_win_set_cursor(self.state.winid, { entry.lnum, entry.col })
                     vim.schedule(function()
                        jump_to_line(self, self.state.bufnr, entry)
                     end)
                  end,
               })
            end,
         },
         sorter = sorters.highlighter_only(opts),

         attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
               --TODO:
               actions.close(prompt_bufnr)
               local selection = action_state.get_selected_entry()

               local sha1 = selection.filename:sub(6)
               for i, en in ipairs(db.index) do
                  if en.id == sha1 then
                     render.on_display = db.index
                     render.show_entry { row_idx = i, untag = false }
                     jump_to_line(nil, render.buf.entry, selection)
                     break
                  end
               end
            end)
            map("i", "<c-space>", actions.to_fuzzy_refine)
            return true
         end,
         push_cursor_on_edit = true,
      })
      :find()
end

local function feed_grep()
   live_grep {
      cwd = "~/.local/share/nvim/feed/",
      entry_maker = gen_from_vimgrep {},
   }
end

return telescope.register_extension {
   exports = {
      feed_grep = feed_grep,
   },
}
