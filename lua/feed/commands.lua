--- TODO: lazy load these ...
local config = require "feed.config"
local fetch = require "feed.fetch"
local feedparser = require "feed.feedparser"
local render = require "feed.render"
local ut = require "feed.utils"

local cmds = {}

-- TODO:
-- 1. unjam: stop the connection pool?
-- 2. add_feed: add to database
-- 3. db_unload: not needed? file handles are just closed... but is that efficient?
-- 4. load_opml: need to load locally
-- 5. show_next: done
-- 6. show_prev: done
-- 7. tag / untag: move here, save to db
-- 8. show: its a better name lol
-- 9. export_opml: locally ...
--

---load opml file to list of sources
---@param file string
function cmds.load_opml(file)
   local feeds = feedparser.parse(file, { type = "opml" })
   for _, feed in ipairs(feeds) do
      local title = feed.title
      local xmlUrl = feed.xmlUrl
      table.insert(config.feeds, { xmlUrl, name = title })
   end
end

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
   vim.cmd "bp" -- TODO: this deleted the index buffer, along with the keymaps
   vim.cmd("colorscheme " .. config.og_colorscheme) -- TODO:
   render.rendered_once = false
end

--- entry buffer actions
function cmds.show_index()
   if render.state.rendered_once then
      if render.state.in_split then
         vim.cmd "q"
         render.state.in_split = false
      end
   else
      render.show_index()
   end
   vim.api.nvim_set_current_buf(render.buf.index)
end

function cmds.next_entry()
   if render.current_index == #render.index then
      return
   end
   render.current_index = render.current_index + 1
   render.show_entry(render.current_index)
end

-- TODO: properly do 'ring' navigation, ie. wrap around
function cmds.prev_entry()
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
   for i, link in ipairs(config.feeds) do
      fetch.update_feed(link, #config.feeds, i)
   end
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

---@param args string[]
local function load_command(args)
   local cmd = table.remove(args, 1)
   return cmds[cmd](unpack(args))
end

-- IDEAS:
-- show random entry
-- show entry from (feed, url, tag, fuzzy find)

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
