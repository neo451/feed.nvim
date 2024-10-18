local config = require "feed.config"
local db = require "feed.db"
local render = require "feed.render"
local fetch = require "feed.fetch"
local ut = require "feed.utils"
local search = require "feed.search"
local opml = require "feed.opml"

local og_colorscheme, og_buffer

local cmds = {}

if not render.state.query then
   render.state.query_string = config.search.default_query
   render.state.query = search.parse_query(config.search.default_query)
end

-- TODO:
-- 1. add/update feed
-- 2. show random entry

function cmds.blowup()
   db:blowup()
end

function cmds.mod()
   vim.api.nvim_set_option_value("modifiable", true, { buf = render.buf.entry })
end

---load opml file to list of sources
---@param filepath string
function cmds.load_opml(filepath)
   filepath = vim.fn.expand(filepath)
   local f = io.open(filepath, "r")
   if f then
      local str = f:read "*a"
      local outlines = opml.import(str).outline
      for _, v in ipairs(outlines) do
         db.feeds:append(v)
      end
      db:save { update_feed = true }
   else
      ut.notify("commands", { msg = "failed to find your opml file" })
   end
end

function cmds.export_opml(filepath)
   filepath = vim.fn.expand(filepath)
   db.feeds:export(filepath)
end

function cmds.search()
   vim.ui.input({ prompt = "Search: " }, function(input)
      if input then
         render.state.query_string = input
         render.state.query = search.parse_query(input) -- TODO: preserve history, and allow direct pass arg or new input window, up/down for history
      end
   end)
end

function cmds.refresh()
   render.refresh()
end

---index buffer commands
function cmds.show_in_browser()
   local entry = render.get_entry()
   local link = entry.link
   vim.ui.open(link)
end

function cmds.show_in_w3m()
   local entry = render.get_entry()
   local ok, _ = pcall(vim.cmd.W3m, entry.link)
   if not ok then
      vim.notify "[feed.nvim]: need w3m.vim installed"
   end
end

function cmds.show_in_split()
   vim.cmd(config.layout.split)
   render.show_entry()
   render.state.in_split = true

   local ok, conform = pcall(require, "conform")
   if ok then
      pcall(conform.format, { formatter = { "injected" }, filetype = "markdown", bufnr = render.buf.entry })
   else
      print(conform)
   end
end

function cmds.show_entry()
   if not render.buf then
      render.prepare_bufs()
   end
   render.show_entry()
end

function cmds.quit_entry()
   if render.state.in_split then
      vim.cmd "q"
      vim.api.nvim_set_current_buf(render.buf.index)
   end
   render.show_index()
end

function cmds.link_to_clipboard()
   vim.fn.setreg("+", render.get_entry().link)
end

function cmds.tag()
   local index
   if render.state.in_entry then
      index = render.current_index
   else
      index = ut.get_cursor_row()
   end
   vim.ui.input({ prompt = "Tag: " }, function(input)
      if input and input ~= "" then
         render.tag(index, input)
      end
   end)
end

function cmds.untag()
   local index
   if render.state.in_entry then
      index = render.current_index
   else
      index = ut.get_cursor_row()
   end
   vim.ui.input({ prompt = "Untag: " }, function(input)
      if input and input ~= "" then
         render.untag(index, input)
      end
   end)
end

--- entry buffer actions
function cmds.show_index()
   og_colorscheme = vim.g.colors_name
   og_buffer = vim.api.nvim_get_current_buf()
   render.refresh()
   -- render.show_index { show = true }
end

function cmds.quit_index()
   if not og_buffer then
      og_buffer = vim.api.nvim_create_buf(true, false)
   end
   vim.api.nvim_set_current_buf(og_buffer)
   vim.cmd.colorscheme(og_colorscheme)
end

function cmds.show_next()
   if render.current_index == #render.on_display then -- TODO: wrong
      return
   end
   render.show_entry { row_idx = render.current_index + 1 }
end

function cmds.show_prev()
   if render.current_index == 1 then
      return
   end
   render.show_entry { row_idx = render.current_index - 1 }
end

---@param link any
---@return string
local function resolve_url_from_entry(link)
   local entry = render.get_entry { row_idx = render.current_index }
   local feed = entry.feed
   local root_url = db.feeds:lookup(feed).htmlUrl
   return ut.url_resolve(root_url, link)
end

function cmds.open_url()
   vim.cmd.normal "yi["
   local text = vim.fn.getreg "0"
   local item = vim.iter(render.state.urls):find(function(v)
      return v[1] == text
   end)
   local link = resolve_url_from_entry(item[2])
   vim.ui.open(link)
end

function cmds.urlview()
   local items = render.state.urls
   vim.ui.select(items, {
      prompt = "urlview",
      format_item = function(item)
         return item[1]
      end,
   }, function(item, _)
      if item then
         local link = resolve_url_from_entry(item[2])
         vim.ui.open(link)
      end
   end)
end

-- TODO: better view
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
   local feeds = db.feeds
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

---remove a feed from db.feeds
---@param str string
function cmds:remove_feed(str) end

---purge a feed from all of the db, including entries
---@param str string #Feed name or link
function cmds:prune(str) end

cmds.update_feed = {
   impl = function(name)
      local feeds = db.feeds
      local feed = feeds:lookup(name)
      fetch.update_feed(feed)
   end,
}
--- **INTEGRATIONS**
function cmds:telescope()
   pcall(vim.cmd.Telescope, "feed")
end

function cmds:grep()
   pcall(vim.cmd.Telescope, "feed_grep")
end

function cmds.which_key()
   local wk = require "which-key"
   wk.show {
      buf = 0,
      ["local"] = true,
      loop = true,
   }
end

render.prepare_bufs()

local augroup = vim.api.nvim_create_augroup("Feed", {})

for lhs, rhs in pairs(config.entry.keys) do
   rhs = (type(rhs) == "function") and rhs or cmds[rhs]
   ut.push_keymap(render.buf.entry, lhs, rhs)
end

for lhs, rhs in pairs(config.index.keys) do
   rhs = (type(rhs) == "function") and rhs or cmds[rhs]
   ut.push_keymap(render.buf.index, lhs, rhs)
end

vim.api.nvim_create_autocmd("BufEnter", {
   group = augroup,
   buffer = render.buf.entry,
   callback = function(ev)
      vim.cmd.colorscheme(config.colorscheme)
      -- require "feed.lualine"
      render.state.in_entry = true
      vim.cmd "set cmdheight=0"
      local buf = ev.buf
      local ok, conform = pcall(require, "conform")
      if ok then
         pcall(conform.format, { formatter = { "injected" }, filetype = "markdown", bufnr = buf })
      else
         print(conform)
      end
      for key, value in pairs(config.entry.opts) do
         pcall(vim.api.nvim_set_option_value, key, value, { buf = ev.buf })
         pcall(vim.api.nvim_set_option_value, key, value, { win = vim.api.nvim_get_current_win() })
      end
      -- TODO: user callback from here callback(ev: { ev, win, entry })
   end,
})

vim.api.nvim_create_autocmd("BufEnter", {
   group = augroup,
   buffer = render.buf.index,
   callback = function(ev)
      vim.cmd.colorscheme(config.colorscheme)
      -- require "feed.lualine"
      vim.cmd "set cmdheight=0"
      local buf = ev.buf
      local ok, conform = pcall(require, "conform")
      if ok then
         pcall(conform.format, { formatter = { "injected" }, filetype = "markdown", bufnr = buf })
      else
         print(conform)
      end
      for key, value in pairs(config.index.opts) do
         pcall(vim.api.nvim_set_option_value, key, value, { buf = ev.buf })
         pcall(vim.api.nvim_set_option_value, key, value, { win = vim.api.nvim_get_current_win() })
      end
   end,
})

local function restore_state()
   vim.cmd "set cmdheight=1"
   vim.wo.winbar = ""
   vim.cmd.colorscheme(og_colorscheme)
end

vim.api.nvim_create_autocmd("BufLeave", {
   group = augroup,
   buffer = render.buf.index,
   callback = restore_state,
})

vim.api.nvim_create_autocmd("BufLeave", {
   group = augroup,
   buffer = render.buf.entry,
   callback = restore_state,
})

return cmds
