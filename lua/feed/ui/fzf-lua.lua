local fzf = require("fzf-lua")
local ui = require("feed.ui")
local DB = require "feed.db"
local Format = require("feed.ui.format")
local builtin = require("fzf-lua.previewer.builtin")

local MyPreviewer = builtin.base:extend()

function MyPreviewer:new(o, opts, fzf_win)
   MyPreviewer.super.new(self, o, opts, fzf_win)
   setmetatable(self, MyPreviewer)
   return self
end

function MyPreviewer:populate_preview_buf(entry_str)
   local tmpbuf = self:get_tmp_buffer()
   self:set_preview_buf(tmpbuf)
   local id = entry_str:sub(-64, -1)
   ui.preview_entry({ buf = tmpbuf, id = id })
   vim.treesitter.start(tmpbuf, "markdown")
   self.win:update_scrollbar()
end

-- Disable line numbering and word wrap
function MyPreviewer:gen_winopts()
   local new_winopts = {
      wrap = true,
      number = false,
      conceallevel = 3,
      spell = false,
   }
   return vim.tbl_extend("force", self.winopts, new_winopts)
end

-- TODO: overide the default .. s
-- TODO: grep

local function feed_search()
   fzf.fzf_live(function(str)
      local on_display = ui.refresh({ query = str, show = false })
      local ret = {}
      for i, id in ipairs(on_display) do
         ret[i] = Format.entry(id) .. (" "):rep(100) .. id
      end
      return ret
   end, {
      prompt = "> ",
      header = "Feed Search",
      exec_empty_query = true,
      previewer = MyPreviewer,
      actions = {
         ["enter"] = function(selected)
            local id = selected[1]:sub(-64, -1)
            ui.show_entry({ id = id })
         end,
      },
   })
end

local function feed_grep(opts)
   local fzf_lua = require("fzf-lua")
   opts = opts or {}
   opts.prompt = "> "
   opts.git_icons = true
   opts.file_icons = true
   opts.color_icons = true
   -- setup default actions for edit, quickfix, etc
   opts.actions = fzf_lua.defaults.actions.files
   -- see preview overview for more info on previewers
   opts.previewer = "builtin"
   opts.fn_transform = function(x)
      local id = x:sub(10, 10 + 63)
      -- return Format.entry(id)
      return fzf_lua.make_entry.file(x, opts)
   end
   opts.cwd = tostring(DB.dir / "data")
   -- we only need 'fn_preprocess' in order to display 'git_icons'
   -- it runs once before the actual command to get modified files
   -- 'make_entry.file' uses 'opts.diff_files' to detect modified files
   -- will probaly make this more straight forward in the future
   opts.fn_preprocess = function(o)
      opts.diff_files = fzf_lua.make_entry.preprocess(o).diff_files
      return opts
   end
   return fzf_lua.fzf_live(function(q)
      return "rg --column --color=always -- " .. vim.fn.shellescape(q or "")
   end, opts)
end

-- We can use our new function on any folder or
-- with any other fzf-lua options ('winopts', etc)
-- _G.live_grep()

return {
   feed_search = feed_search,
   feed_grep = feed_grep
}
