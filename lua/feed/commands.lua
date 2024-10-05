local config = require "feed.config"
local ut = require "feed.utils"

-- IDEAS:
-- show random entry
-- show entry from (feed, url, tag, fuzzy find)

local cmds = {}

-- TODO:
-- 1. unjam: stop the connection pool?
-- 2. add_feed: add to database
-- 3. db_unload: not needed? file handles are just closed... but is that efficient?
-- 6. tag / untag: save to db
-- 7. show: its a better name lol

--- TODO: config.feeds and opml imported should be <link, table> to avoid dup

---load opml file to list of sources
---@param filepath string
function cmds.load_opml(filepath)
   local opml = require "feed.opml"
   local outlines = opml.import(filepath).outline
   local index_opml = opml.import(config.opml)
   vim.list_extend(index_opml.outline, outlines)
   index_opml:export(config.opml)
   vim.list_extend(config.feeds, outlines)
end

---index buffer commands
function cmds.show_in_browser()
   local render = require "feed.render"
   vim.ui.open(render.current_entry().link)
end

function cmds.show_in_w3m()
   local render = require "feed.render"
   if ut.check_command "W3m" then
      vim.cmd("W3m " .. render.current_entry().link)
   else
      vim.notify "[feed.nvim]: need w3m.nvim installed"
   end
end

local function current_index()
   local render = require "feed.render"
   local index = vim.api.nvim_win_get_cursor(0)[1] - 1
   render.current_index = index
   return index
end

function cmds.show_in_split()
   local render = require "feed.render"
   render.state.in_split = true
   vim.cmd(config.split)
   vim.cmd(config.split:find "v" and "wincmd k" or "wincmd j")
   render.show_entry(current_index())
end

function cmds.show_entry()
   local render = require "feed.render"
   render.state.in_entry = true
   render.show_entry(current_index())
end

function cmds.link_to_clipboard()
   local render = require "feed.render"
   vim.fn.setreg("+", render.current_entry().link)
end

function cmds.tag()
   local render = require "feed.render"
   local input = vim.fn.input "Tag: "
   render.current_entry().tags[input] = true
   -- db:save() -- TODO: do it on exit / or only if ":w" , make an option
   render.show_index() -- TODO: inefficient??, only rerender the one entry
end

function cmds.untag()
   local render = require "feed.render"
   local input = vim.fn.input "Untag: "
   render.current_entry().tags[input] = nil
   render.show_index()
end

function cmds.quit_index()
   local render = require "feed.render"
   --TODO: jump to the buffer before the index
   --- TODO: check if in index
   if ut.check_command "ZenMode" then
      vim.cmd "ZenMode"
   end
   vim.cmd "bd"
   vim.cmd.colorscheme(config.og_colorscheme)
   render.rendered_once = false
end

--- entry buffer actions
function cmds.show_index()
   local render = require "feed.render"
   config.og_colorscheme = vim.g.colors_name
   if not render.state.in_entry then
      if not render.buf.index then
         render.prepare_bufs(cmds)
      end
      render.show_index()
   else
      if render.state.index_rendered then
         if render.state.in_split then
            vim.cmd "q"
            render.state.in_split = false
         else
            vim.api.nvim_set_current_buf(render.buf.index)
         end
      end
   end
end

function cmds.show_next()
   local render = require "feed.render"
   local db = require("feed.db").db(config.db_dir)
   if render.current_index == #db.index then
      return
   end
   render.current_index = render.current_index + 1
   render.show_entry(render.current_index)
end

function cmds.show_prev()
   local render = require "feed.render"
   if render.current_index == 1 then
      return
   end
   render.current_index = render.current_index - 1
   render.show_entry(render.current_index)
end

function cmds.list_feeds()
   print(vim.inspect(vim.tbl_values(config.feeds)))
end

function cmds.update()
   local db = require("feed.db").db(config.db_dir)
   local fetch = require "feed.fetch"
   local opml = require("feed.opml").import(config.opml)
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

   if opml then
      config.feeds = vim.list_extend(config.feeds, opml.outline) -- TODO: remove duplicates ...
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

-- function cmds.update_feed(name)
--    fetch.update_feed(config.feeds[name], 1, 1)
-- end

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

---@param args string[]
local function load_command(args)
   local cmd = table.remove(args, 1)
   if type(cmds[cmd]) == "table" then
      return cmds[cmd].impl(unpack(args))
   elseif type(cmds[cmd]) == "function" then
      return cmds[cmd](unpack(args))
   end
end

return {
   load_command = load_command,
   cmds = cmds,
}
