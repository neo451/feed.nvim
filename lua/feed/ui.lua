local Config = require("feed.config")
local DB = require("feed.db")
local Format = require("feed.ui.format")
local Markdown = require("feed.ui.markdown")
local Curl = require("feed.curl")
local Opml = require("feed.opml")
local Fetch = require "feed.fetch"
local Win = require "feed.ui.window"
local ut = require("feed.utils")
local read_file = ut.read_file
local save_file = ut.save_file

local hl = vim.hl or vim.highlight
local api = vim.api
local feeds = DB.feeds
local get_buf_urls = ut.get_buf_urls
local resolve_and_open = ut.resolve_and_open


local state = require "feed.ui.state"

local og = {}

local M = {
   state = state
}

for name, f in pairs(require "feed.ui.nui") do
   M[name] = f
end

state.query = Config.search.default_query
local ns = api.nvim_create_namespace("feed_index")

local function show_index()
   if not state.index or not state.index:valid() then
      state.index = Win.new({
         wo = Config.options.index.wo,
         bo = Config.options.index.bo,
         keys = Config.keys.index,
         autocmds = {
            BufEnter = function()
               vim.o.cmdheight = 0
               og.colorscheme = vim.g.colors_name
               og.cmdheight = vim.o.cmdheight
               pcall(vim.cmd.colorscheme, Config.colorscheme)
            end,
            BufLeave = function(self)
               vim.o.cmdheight = og.cmdheight
               pcall(vim.cmd.colorscheme, og.colorscheme)
               self:close()
            end,
         }
      })
   end
   local buf, win = state.index.buf, state.index.win
   vim.wo[win].winbar = M.show_winbar()
   api.nvim_buf_set_name(buf, "FeedIndex")
   state.entries = state.entries or DB:filter(state.query)
   vim.bo[buf].modifiable = true
   api.nvim_buf_set_lines(buf, 0, -1, false, {}) -- clear lines
   for i, id in ipairs(state.entries) do
      api.nvim_buf_set_lines(buf, i - 1, i, false, { Format.entry(id, Config.layout) })
   end
   for i = 1, #state.entries do
      local acc = 0
      for _, sect in ipairs(Config.layout) do
         local width = sect.width or math.huge
         hl.range(buf, ns, sect.color, { i - 1, acc }, { i - 1, acc + width })
         acc = acc + width + 1
      end
   end
   api.nvim_buf_set_lines(buf, #state.entries, #state.entries + 1, false, { "" })
   vim.bo[buf].modifiable = false
   api.nvim_exec_autocmds("User", { pattern = "ShowIndexPost" })
end

---get entry base on current context, and update current_index
---@return feed.entry
---@return string
local function get_entry(ctx)
   ctx = ctx or {}
   local id
   if ctx.id then
      id = ctx.id
      if ut.in_index() then
         state.cur = api.nvim_win_get_cursor(0)[1]
      elseif state.entries then
         for i, v in ipairs(state.entries) do
            if v == id then
               state.cur = i
            end
         end
      end
   elseif ctx.row then
      state.cur = ctx.row
      id = state.entries[state.cur]
   elseif ut.in_index() then
      state.cur = api.nvim_win_get_cursor(0)[1]
      id = state.entries[state.cur]
   elseif ut.in_entry() then
      id = state.entries[state.cur]
   else
      vim.notify("no context to show entry")
   end
   return DB[id], id
end

---Mark entry in db with read tag, if index rendered then grey out the entry
---@param id string
local function mark_read(id)
   DB:tag(id, "read")
   if state.index and state.index:valid() then
      local buf = state.index.buf
      api.nvim_buf_clear_namespace(buf, ns, state.cur - 1, state.cur)
      hl.range(buf, ns, "FeedRead", { state.cur - 1, 0 }, { state.cur - 1, -1 })
   end
end

---temparay solution for getting rid of junks and get clean markdown
---@param lines string[]
---@return string[]
local function entry_filter(lines)
   local idx
   local res = {}
   for i, v in ipairs(lines) do
      if v:find("^# ") or v:find("^## ") then
         idx = i
         break
      end
   end
   if idx then
      for i = idx, #lines do
         res[#res + 1] = lines[i]
      end
   else
      return lines
   end
   return res
end

---@param buf integer
---@param body string[]
---@param id string
local function set_content(buf, body, id)
   vim.bo[buf].modifiable = true
   api.nvim_buf_set_lines(buf, 0, -1, false, {}) -- clear buf lines

   local header = {}
   for _, v in ipairs({ "title", "author", "feed", "link", "date" }) do
      header[#header + 1] = ut.capticalize(v) .. ": " .. Format[v](id)
   end

   header[#header + 1] = ""

   body = entry_filter(body)
   local lines = vim.list_extend(header, body)

   for i, v in ipairs(lines) do
      v = vim.trim(ut.unescape(v:gsub("\n", "")))
      api.nvim_buf_set_lines(buf, i - 1, i, false, { v })
   end
end

---@param ctx? { row: integer, id: string, buf: integer, link: string, read: boolean }
function M.preview_entry(ctx)
   ctx = ctx or {}
   local entry, id = get_entry(ctx)
   if not entry then return end

   local buf
   if ctx.buf and api.nvim_buf_is_valid(ctx.buf) then
      buf = ctx.buf
   else
      buf = api.nvim_create_buf(false, true)
   end
   local str = ut.read_file(DB.dir .. "/data/" .. id)
   if str then
      local lines = vim.split(str, "\n")
      set_content(buf, lines, id)
      if ctx.read then
         mark_read(id)
      end
   else
      vim.notify "no content to preview"
   end
end

---@param ctx? { row: integer, id: string, buf: integer, link: string }
local function show_entry(ctx)
   ctx = ctx or {}
   local entry, id = get_entry(ctx)
   if not entry then return end

   local buf
   if ctx.buf and api.nvim_buf_is_valid(ctx.buf) then
      buf = ctx.buf
   else
      buf = api.nvim_create_buf(false, true)
   end

   if ctx.link then
      Markdown.convert {
         link = ctx.link,
         cb = function(lines)
            set_content(buf, lines, id)
         end,
      }
   elseif entry.content then
      Markdown.convert {
         src = entry.content(),
         cb = function(lines)
            set_content(buf, lines, id)
         end,
      }
   else
      local str = ut.read_file(DB.dir .. "/data/" .. id)
      if str then
         local lines = vim.split(str, "\n")
         set_content(buf, lines, id)
      else
         vim.notify "no content to preview"
      end
   end

   Config.options.entry.wo.winbar = M.show_keyhints()

   state.entry = Win.new {
      prev_win = (state.index and state.index:valid()) and state.index.win or nil,
      buf = buf,
      wo = Config.options.entry.wo,
      bo = Config.options.entry.bo,
      keys = Config.keys.entry,
      ft = "markdown",
      autocmds = {
         BufEnter = function()
            vim.o.cmdheight = 0
            og.colorscheme = vim.g.colors_name
            og.cmdheight = vim.o.cmdheight
            pcall(vim.cmd.colorscheme, Config.colorscheme)
         end,
         BufLeave = function(self)
            vim.o.cmdheight = og.cmdheight
            pcall(vim.cmd.colorscheme, og.colorscheme)
            self:close()
         end
      }
   }
   state.urls = get_buf_urls(buf, DB[id].link)

   local win = state.entry.win

   api.nvim_buf_set_name(buf, "FeedEntry")
   api.nvim_win_set_cursor(win, { 1, 0 })
   api.nvim_exec_autocmds("User", { pattern = "ShowEntryPost" })

   mark_read(id)
end

M.show_full    = function()
   local entry = get_entry()
   if entry and entry.link then
      show_entry { link = entry.link, buf = state.entry.buf }
   else
      vim.notify "no link to fetch"
   end
end

M.refresh      = function(opts)
   opts = opts or {}
   opts.show = vim.F.if_nil(opts.show, true)
   state.query = opts.query or state.query
   DB:update()
   state.entries = DB:filter(state.query)
   if opts.show then
      show_index()
      api.nvim_win_set_cursor(0, { 1, 0 })
   end
   return state.entries
end

M.quit         = function()
   if ut.in_index() then
      state.index:close()
      state.index = nil
   elseif ut.in_entry() then
      state.entry:close()
   end
end

M.show_prev    = function()
   if state.cur > 1 then
      show_entry({ row = state.cur - 1, buf = state.entry.buf })
   end
end

M.show_next    = function()
   if state.cur < #state.entries then
      show_entry({ row = state.cur + 1, buf = state.entry.buf })
   end
end

M.show_urls    = function()
   local base = get_entry().link
   M.select(state.urls, {
      prompt = "urlview",
      format_item = function(item)
         return item[1]
      end,
   }, function(item)
      if item then
         resolve_and_open(item[2], base)
      end
   end)
end

M.open_url     = function()
   local base = get_entry().link
   local text = vim.fn.expand("<cfile>")
   if ut.looks_like_url(text) then
      resolve_and_open(text, base)
   elseif not vim.tbl_isempty(vim.ui._get_urls()) then
      resolve_and_open(vim.ui._get_urls()[1], base)
   else
      local item = vim.iter(state.urls):find(function(v)
         return v[1] == text
      end)
      if item then
         resolve_and_open(item[2], base)
      end
   end
   vim.bo.modifiable = false
end

M.show_browser = function()
   local entry, id = get_entry()
   if entry and entry.link then
      mark_read(id)
      vim.ui.open(entry.link)
   else
      vim.notify("no link for entry you try to open")
   end
end

M.show_log     = function()
   local str = ut.read_file(vim.fn.stdpath("data") .. "/feed.nvim.log") or ""
   M.split({}, "50%", vim.split(str, "\n"))
end

M.show_hints   = function()
   local maps
   if ut.in_entry() then
      maps = Config.keys.entry
   elseif ut.in_index() then
      maps = Config.keys.index
   else
      maps = Config.keys.index
   end

   local lines = {}
   for k, v in pairs(maps) do
      lines[#lines + 1] = v .. " -> " .. k
   end

   M.split({
      wo = {
         winbar = "%#Title# Key Hints",
      }
   }, "50%", lines)
end

---Open split to show entry
---@param percentage any
M.show_split   = function(percentage)
   local _, id = get_entry()
   local split = M.split({}, percentage or "50%")
   M.preview_entry({ buf = split.buf, id = id, read = true })
   ut.wo(split.win, Config.options.entry.wo)
   ut.bo(split.buf, Config.options.entry.bo)
end

M.show_feeds   = function(percentage)
   local split = M.split({
      wo = {
         spell = false,
         winbar = "%#Title# Feedlist",
      },
      bo = {
         filetype = "markdown",
      },
      autocmds = {
         BufLeave = function(self)
            self:close()
         end
      }
   }, percentage or "50%", {})

   local function node_to_md(heading, items)
      local res = {}
      res[#res + 1] = "# " .. heading
      for k, v in pairs(items) do
         res[#res + 1] = "- " .. ut.capticalize(k) .. ": " .. (type(v) == "table" and vim.inspect(v) or v)
      end
      res[#res + 1] = ""
      return res
   end

   local lines = {}

   for url, feed in pairs(feeds) do
      if type(feed) == "table" then
         lines = vim.list_extend(lines, node_to_md(feed.title or url, feed))
      end
   end

   vim.api.nvim_buf_set_lines(split.buf, 0, -1, false, lines)
end

---In Index: prompt for input and refresh
---Everywhere else: openk search backend
---@param q string
M.search       = function(q)
   local backend = ut.choose_backend(Config.search.backend)
   if q then
      M.refresh({ query = q })
   elseif ut.in_index() or not backend then
      M.input({
         prompt = "Feed query: ",
         default = Config.search.show_last and state.query .. " " or ""
      }, function(val)
         if not val then
            return
         end
         M.refresh({ query = val })
      end)
   else
      local engine = require("feed.ui." .. backend)
      engine.feed_search()
   end
end

-- TODO: support argument
M.grep         = function()
   local backend = ut.choose_backend(Config.search.backend)
   local engine = require("feed.ui." .. backend)
   engine.feed_grep()
end

M.load_opml    = function(path)
   if not path then
      return
   end
   local str
   if ut.looks_like_url(path) then
      str = Curl.get(path, {}).stdout
   else
      path = vim.fn.expand(path)
      str = read_file(path)
   end
   if str then
      local outlines = Opml.import(str)
      if outlines then
         for k, v in pairs(outlines) do
            feeds[k] = v
         end
      else
         vim.notify("failed to parse your opml file")
      end
      DB:save_feeds()
   else
      vim.notify("failed to open your opml file")
   end
end

M.export_opml  = function(fp)
   if not fp then
      return
   end
   fp = vim.fn.expand(fp)
   if not fp then
      return
   end
   local str = Opml.export(feeds)
   local ok = save_file(fp, str)
   if not ok then
      vim.notify("failed to export your opml file")
   end
end

M.dot          = function() end
local tag_hist = {}


M.undo = function()
   local act = table.remove(tag_hist, #tag_hist)
   if not act then
      return
   end
   if act.type == "tag" then
      M.untag(act.tag, act.id)
   elseif act.type == "untag" then
      M.tag(act.tag, act.id)
   end
end

M.tag = function(t, id)
   id = id or select(2, get_entry())
   if not t or not id then
      return
   end
   DB:tag(id, t)
   if ut.in_index() then
      M.refresh()
   end
   M.dot = function()
      M.tag(t)
   end
   table.insert(tag_hist, { type = "tag", tag = t, id = id })
end

M.untag = function(t, id)
   id = id or select(2, get_entry())
   if not t or not id then
      return
   end
   DB:untag(id, t)
   if ut.in_index() then
      M.refresh()
   end
   M.dot = function()
      M.untag(t)
   end
   table.insert(tag_hist, { type = "untag", tag = t, id = id })
end

---@param url string
M.update_feed = function(url)
   local Coop = require "coop"
   if not url or not ut.looks_like_url(url) then
      return
   end
   Coop.spawn(function()
      local ok = Fetch.update_feed_co(url, { force = true })
      vim.notify(ut.url2name(url, feeds) .. (ok and " success" or " failed"))
   end)
end

---@param url string
M.prune_feed = function(url)
   if not url or not ut.looks_like_url(url) then
      return
   end
   for id, entry in DB:iter() do
      if entry.feed == url then
         DB:rm(id)
      end
   end
   feeds[url] = false
   DB:save_feeds()
end

M.show_winbar = require "feed.ui.bar".show_winbar
M.show_keyhints = require "feed.ui.bar".show_keyhints
M.show_index = show_index
M.show_entry = show_entry
M.get_entry = get_entry

return M
