local config = require "feed.config"
local ut = require "feed.utils"
local og_colorscheme
local og_buffer

local opml_path = config.db_dir .. "/feeds.opml" --TODO: ///

-- IDEAS:
-- show random entry
-- show entry from (feed, url, tag, fuzzy find)

local cmds = {}

-- TODO:
-- 1. unjam: stop the connection pool?
-- 2. add_feed: add to database
-- 3. db_unload: not needed? file handles are just closed... but is that efficient?

function cmds.blowup()
   require "feed.db"(config.db_dir):blowup()
end

---load opml file to list of sources
---@param filepath string
function cmds.load_opml(filepath)
   local opml = require "feed.opml"
   local outlines = opml.import(filepath).outline
   local index_opml = opml.import(opml_path)
   for _, v in ipairs(outlines) do
      index_opml:append(v)
   end
   index_opml:export(opml_path)
end

function cmds.refresh()
   local render = require "feed.render"
   render.refresh()
end

---index buffer commands
function cmds.show_in_browser()
   local render = require "feed.render"
   vim.ui.open(render.get_entry_under_cursor().link)
end

function cmds.show_in_w3m()
   local render = require "feed.render"
   if ut.check_command "W3m" then
      vim.cmd("W3m " .. render.get_entry_under_cursor().link)
   else
      vim.notify "[feed.nvim]: need w3m.nvim installed"
   end
end

function cmds.show_in_split()
   local render = require "feed.render"
   render.state.in_split = true
   vim.cmd(config.split)
   vim.cmd(config.split:find "v" and "wincmd k" or "wincmd j")
   render.show_entry_under_cursor()
end

function cmds.show_entry()
   local render = require "feed.render"
   render.state.in_entry = true
   render.show_entry_under_cursor()
end

function cmds.link_to_clipboard()
   local render = require "feed.render"
   vim.fn.setreg("+", render.get_entry_under_cursor().link)
end
---@return integer
local function get_cursor_col()
   return vim.api.nvim_win_get_cursor(0)[1] - 1
end

function cmds.tag()
   local render = require "feed.render"
   local input = vim.fn.input "Tag: "
   local db = require "feed.db"(config.db_dir)
   db[get_cursor_col()].tags[input] = true
   db:save() -- TODO: do it on exit / or only if ":w" , make an option
   render.show_index() -- TODO: inefficient??, only rerender the one entry
end

function cmds.untag()
   local render = require "feed.render"
   local input = vim.fn.input "Untag: "
   local db = require "feed.db"(config.db_dir)
   db[get_cursor_col()].tags[input] = nil
   db:save() -- TODO: do it on exit / or only if ":w" , make an option
   render.show_index() -- TODO: inefficient??, only rerender the one entry
end

--- entry buffer actions
function cmds.show_index()
   local render = require "feed.render"
   og_colorscheme = vim.g.colors_name
   og_buffer = vim.api.nvim_get_current_buf()
   render.show_index()
end

function cmds.quit_index()
   if ut.check_command "ZenMode" then
      vim.cmd "ZenMode"
   end
   vim.api.nvim_set_current_buf(og_buffer)
   vim.cmd.colorscheme(og_colorscheme)
end

function cmds.show_next()
   local render = require "feed.render"
   local db = require "feed.db"(config.db_dir)
   if render.current_index == #db.index then
      return
   end
   render.show_entry(render.current_index + 1)
end

function cmds.show_prev()
   local render = require "feed.render"
   if render.current_index == 1 then
      return
   end
   render.show_entry(render.current_index - 1)
end

function cmds.list_feeds()
   print(vim.inspect(vim.tbl_values(config.feeds)))
end

function cmds.update()
   local db = require "feed.db"(config.db_dir)
   local fetch = require "feed.fetch"
   local opml = require("feed.opml").import(opml_path)
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
   if opml then
      config.feeds = vim.list_extend(config.feeds, opml.outline)
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
   if ut.check_command "Telescope" then
      vim.cmd "Telescope feed"
   end
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
