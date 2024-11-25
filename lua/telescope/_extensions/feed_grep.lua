local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
   error "This extension requires telescope.nvim"
end
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local previewers = require "telescope.previewers"
local builtins = require "telescope.builtin"

local ut = require "feed.utils"
local db = ut.require "feed.db"
local render = require "feed.render"
local format = require "feed.format"
local config = require "feed.config"

local parse = function(t)
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

local execute_keys = {
   text = function(t)
      return parse(t)[4], true
   end,

   ordinal = function(t)
      return t.text
   end,
}

local mt

mt = {
   display = function(entry)
      local en = db[entry.filename]
      return format.entry_name(en)
   end,

   __index = function(t, k)
      local raw = rawget(mt, k)
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

local ns = vim.api.nvim_create_namespace "feed.grep"

local jump_to_line = function(win, bufnr, entry)
   pcall(vim.api.nvim_buf_clear_namespace, bufnr, ns, 0, -1)

   if entry.lnum and entry.lnum > 0 then
      local lnum, lnend = entry.lnum - 1, (entry.lnend or entry.lnum) - 1

      local col, colend = 0, -1
      if entry.col and entry.colend then
         col, colend = entry.col - 1, entry.colend - 1
      end

      for i = lnum, lnend do
         pcall(vim.api.nvim_buf_add_highlight, bufnr, ns, "TelescopePreviewLine", i, i == lnum and col or 0, i == lnend and colend or -1)
      end

      local middle_ln = math.floor(lnum + (lnend - lnum) / 2)
      pcall(vim.api.nvim_win_set_cursor, win or 0, { middle_ln + 1, 0 })
      vim.api.nvim_buf_call(bufnr, function()
         vim.cmd "norm! zz"
      end)
   end
end

local function feed_grep()
   local opts = {
      prompt_title = "Feed grep",
      cwd = db.dir .. "/data/",
      entry_maker = function(line)
         return setmetatable({ line }, mt)
      end,
      previewer = previewers.new_buffer_previewer {
         title = "Feed Grep Preview",
         define_preview = function(self, entry, _)
            render.show_entry { buf = self.state.bufnr, id = entry.filename, untag = false }
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
            local id = selection.filename
            render.entry = vim.api.nvim_create_buf(false, true)
            render.show_entry { id = id, untag = false }
            -- jump_to_line(nil, render.state.entry_buf, selection)
         end)
         return true
      end,
   }
   opts = vim.tbl_extend("force", opts, config.integrations.telescope)
   builtins.live_grep(opts)
end

return telescope.register_extension {
   exports = {
      feed_grep = feed_grep,
   },
}
