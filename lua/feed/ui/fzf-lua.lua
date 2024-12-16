local fzf = require("fzf-lua")
local ui = require("feed.ui")
local db = require("feed.db")
local format = require("feed.ui.format")
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
   ui.show_entry({ buf = tmpbuf, id = id })
   vim.treesitter.start(tmpbuf, "markdown")
   self.win:update_scrollbar()
end

-- Disable line numbering and word wrap
function MyPreviewer:gen_winopts()
   local new_winopts = {
      wrap = true,
      number = false,
      conceallevel = 3,
   }
   return vim.tbl_extend("force", self.winopts, new_winopts)
end

-- TODO: overide the default .. s
-- TODO: grep

-- FIX: open entry not working

local function feed_search()
   fzf.fzf_live(function(str)
      local on_display = ui.refresh({ query = str, show = false })
      local ret = {}
      for i, id in ipairs(on_display) do
         ret[i] = format.entry(db[id]) .. (" "):rep(100) .. id
      end
      return ret
   end, {
      prompt = "> ",
      header = "Feed Search",
      exec_empty_query = true,
      previewer = MyPreviewer,
      actions = {
         ["ctrl-y"] = function(selected)
            local id = selected[1]:sub(-64, -1)
            ui.show_entry({ id = id })
         end,
      },
   })
end

return {
   feed_search = feed_search,
}
