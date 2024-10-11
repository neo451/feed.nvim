local config = require "feed.config"
local og_colorscheme
local og_buffer

local opml_path = config.db_dir .. "/feeds.opml" --TODO: ///

local db = require "feed.db"(config.db_dir)
local render = require "feed.render"
local opml = require "feed.opml"
local fetch = require "feed.fetch"

local cmds = {}

-- TODO:
-- 1. add/update feed
-- 2. show random entry

function cmds.blowup()
   db:blowup()
end

---load opml file to list of sources
---@param filepath string
function cmds.load_opml(filepath)
   local outlines = opml.import(filepath).outline
   local index_opml = opml.import(opml_path)
   for _, v in ipairs(outlines) do
      index_opml:append(v)
   end
   index_opml:export(opml_path)
end

function cmds.export_opml(filepath)
   local index_opml = opml.import(config.db_dir .. "/feeds.opml")
   index_opml:export(filepath)
end

function cmds.refresh()
   render.refresh()
end

---index buffer commands
function cmds.show_in_browser()
   local link = render.get_entry_under_cursor().link
   vim.ui.open(link)
end

function cmds.show_in_w3m()
   local ok, _ = pcall(vim.cmd.W3m, render.get_entry_under_cursor().link)
   if not ok then
      vim.notify "[feed.nvim]: need w3m.vim installed"
   end
end

function cmds.show_in_split()
   vim.cmd(config.layout.split)
   render.state.in_split = true
   render.show_entry_under_cursor()
end

function cmds.show_entry()
   render.show_entry_under_cursor()
end

function cmds.quite_entry()
   if render.state.in_split then
      vim.cmd "q"
      vim.api.nvim_set_current_buf(render.buf.index)
   end
   render.show_index()
end

function cmds.link_to_clipboard()
   vim.fn.setreg("+", render.get_entry_under_cursor().link)
end

---@return integer
local function get_cursor_col()
   return vim.api.nvim_win_get_cursor(0)[1] - 1
end

function cmds.tag()
   local input = vim.fn.input "Tag: "
   db[get_cursor_col()].tags[input] = true
   db:save() -- TODO: do it on exit / or only if ":w" , make an option
   render.show_index() -- TODO: inefficient??, only rerender the one entry
end

function cmds.untag()
   local input = vim.fn.input "Untag: "
   db[get_cursor_col()].tags[input] = nil
   db:save() -- TODO: do it on exit / or only if ":w" , make an option
   render.show_index() -- TODO: inefficient??, only rerender the one entry
end

--- entry buffer actions
function cmds.show_index()
   if config.zenmode then
      pcall(vim.cmd.ZenMode)
   end
   og_colorscheme = vim.g.colors_name
   og_buffer = vim.api.nvim_get_current_buf()
   vim.cmd.colorscheme(config.colorscheme)
   render.show_index()
end

function cmds.quit_index()
   if config.zenmode then
      pcall(vim.cmd.ZenMode)
   end
   vim.api.nvim_set_current_buf(og_buffer)
   vim.cmd.colorscheme(og_colorscheme)
end

function cmds.show_next()
   if render.current_index == #db.index then -- TODO: wrong
      return
   end
   render.show_entry(render.current_index + 1)
end

function cmds.show_prev()
   if render.current_index == 1 then
      return
   end
   render.show_entry(render.current_index - 1)
end

function cmds.urlview()
   require "feed.urlview"(table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), ""))
end

function cmds.list_feeds()
   print(vim.inspect(vim.tbl_values(config.feeds)))
end

function cmds.update()
   local ok, progress = pcall(require, "fidget.progress")
   local handle
   if not ok then
      vim.notify "fidget not found" -- TODO: make a simple message printer if fidget not found...
   else
      handle = progress.handle.create {
         title = "Feed update",
         message = "fetching feeds...",
         percentage = 0,
      }
   end

   -- TODO: iterate over opml, identify unstored feeds, fetch current info, and store to local opml index
   local feeds = opml.import(config.db_dir .. "/feeds.opml")
   if feeds then
      vim.list_extend(config.feeds, feeds.outline)
   end

   for _, link in ipairs(config.feeds) do
      fetch.update_feed(link, #config.feeds, handle)
   end

   -- db:sort() -- TODO:
   db:save()
end

---add a feed to database
---@param str string
function cmds:add_feed(str) end

function cmds.update_feed(name) end

--- **INTEGRATIONS**
function cmds:telescope()
   pcall(vim.cmd.Telescope, "feed")
end

function cmds.which_key()
   local wk = require "which-key"
   wk.show {
      buf = 0,
      ["local"] = true,
      loop = true,
   }
end

return cmds
