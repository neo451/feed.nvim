--- TODO: lazy load these ...
local config = require "feed.config"
local fetch = require "feed.fetch"
local render = require "feed.render"
local ut = require "feed.utils"
local db = require("feed.db").db(config.db_dir)

-- IDEAS:
-- show random entry
-- show entry from (feed, url, tag, fuzzy find)

local cmds = {}

-- TODO:
-- 1. unjam: stop the connection pool?
-- 2. add_feed: add to database
-- 3. db_unload: not needed? file handles are just closed... but is that efficient?
-- 4. load_opml: need to load locally
-- 5. export_opml
-- 6. tag / untag: save to db
-- 7. show: its a better name lol

cmds.load_opml = {
   ---load opml file to list of sources
   ---@param file string
   impl = function(file)
      local feedparser = require "feed.feedparser"
      local feeds = feedparser.parse(file, { type = "opml" })
      for _, feed in ipairs(feeds) do
         local title = feed.title
         local xmlUrl = feed.xmlUrl
         table.insert(config.feeds, { xmlUrl, name = title })
      end
   end,
   complete = function(lead)
      local tab = { "abc", "efg", "hijk" }
      return vim.iter(tab):filter(function(t)
         return t:find(lead) ~= nil
      end)
   end,
}

local function Fee(opts)
   local fargs = opts.fargs
   local sub_key = table.remove(fargs, 1)
   local sub_cmd = cmds[sub_key]
   if not sub_cmd then
      vim.notify("Feed: Unknown command: " .. sub_key, vim.log.levels.ERROR)
   end
   sub_cmd.impl(fargs, opts)
end

vim.api.nvim_create_user_command("Fee", Fee, {
   nargs = "+",
   desc = "Feed comp test",
   complete = function(arg_lead, cmdline, _)
      print(arg_lead)
   end,
})

---index buffer commands
function cmds.show_in_browser()
   vim.ui.open(render.current_entry().link)
end

function cmds.show_in_w3m()
   if ut.check_command "W3m" then
      vim.cmd("W3m " .. render.current_entry().link)
   else
      vim.notify "[rss.nvim]: need w3m.nvim installed"
   end
end

local function current_index()
   local index = vim.api.nvim_win_get_cursor(0)[1] - 1
   render.current_index = index
   return index
end

function cmds.show_in_split()
   render.state.in_split = true
   vim.cmd(config.split)
   vim.cmd(config.split:find "v" and "wincmd k" or "wincmd j")
   render.show_entry(current_index())
end

function cmds.show_entry()
   render.state.in_entry = true
   render.show_entry(current_index())
end

function cmds.link_to_clipboard()
   vim.fn.setreg("+", render.current_entry().link)
end

function cmds.tag()
   local input = vim.fn.input "Tag: "
   render.current_entry().tags[input] = true
   -- db:save() -- TODO: do it on exit / or only if ":w" , make an option
   render.show_index() -- TODO: inefficient??, only rerender the one entry
end

function cmds.untag()
   local input = vim.fn.input "Untag: "
   render.current_entry().tags[input] = nil
   render.show_index()
end

function cmds.quit_index()
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
   if not render.state.in_entry then
      if not render.buf.index then
         print "reerer"
         render.prepare_bufs(cmds)
      end
      render.show_index()
   else
      if render.state.rendered_once then
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
   if render.current_index == #db.index then
      return
   end
   render.current_index = render.current_index + 1
   render.show_entry(render.current_index)
end

-- TODO: properly do 'ring' navigation, ie. wrap around
function cmds.show_prev()
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
      vim.cmd "Telescope rss"
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
   Pr(args)
   local cmd = table.remove(args, 1)
   return cmds[cmd](unpack(args))
end

local popup = require "plenary.popup"

return {
   load_command = load_command,
   cmds = cmds,
}

-- vim.api.nvim_create_autocmd("VimLeavePre", {
--    pattern = "*.md",
--    callback = function()
--       print "leave!"
--       db:save()
--       -- autocmds.update()
--    end,
-- })
