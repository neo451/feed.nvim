local Config = require("feed.config")
local ut = require("feed.utils")
---@type feed.db
local DB = require("feed.db")
local Format = require("feed.ui.format")
local NuiText = require("nui.text")
local NuiLine = require("nui.line")
local NuiTree = require("nui.tree")
local Markdown = require("feed.ui.markdown")
local Nui = require("feed.ui.nui")
local Curl = require("feed.curl")
local Opml = require("feed.parser.opml")
local fetch = require "feed.fetch"
local Win = require "feed.ui.window"
local read_file = ut.read_file
local save_file = ut.save_file


local api = vim.api
local feeds = DB.feeds
local feedlist = ut.feedlist
local get_buf_urls = ut.get_buf_urls
local resolve_and_open = ut.resolve_and_open
local Split = Nui.split

local on_display
local current_entry, current_index


local og = {
   colorscheme = vim.g.colors_name,
   cmdheight = vim.o.cmdheight
}

local state = {
   index = nil,
   entry = nil
}

local M = {
   state = state
}

vim.g.feed_current_query = Config.search.default_query

local function show_index()
   if not state.index or not state.index:valid() then
      state.index = Win.new({
         wo = Config.options.index.wo,
         bo = Config.options.index.bo,
         keys = {
            { "q",    ":Feed quit" },
            { "<cr>", ":Feed entry" },
            { "r",    ":Feed refresh" },
            { "s",    ":Feed search" },
         },
         autocmds = {
            [{ "BufEnter", "WinEnter", "VimResized" }] = function()
               vim.wo.winbar = M.show_winbar()
               vim.o.cmdheight = 0
               pcall(vim.cmd.colorscheme, Config.colorscheme)
            end,
            [{ "BufLeave", "WinLeave" }] = function()
               vim.o.cmdheight = og.cmdheight
               vim.cmd.colorscheme(og.colorscheme)
            end
         }
      })
   end
   local buf = state.index.buf
   pcall(api.nvim_buf_set_name, buf, "FeedIndex")
   on_display = on_display or DB:filter(vim.g.feed_current_query)
   vim.bo[buf].modifiable = true
   api.nvim_buf_set_lines(buf, 0, -1, false, {}) -- clear lines
   for i, id in ipairs(on_display) do
      Format.gen_nui_line(id, false):render(buf, -1, i)
   end
   api.nvim_buf_set_lines(buf, #on_display, #on_display + 1, false, { "" })
   api.nvim_exec_autocmds("User", { pattern = "ShowIndexPost" })
end

---@return feed.entry
---@return string
local function get_entry(opts)
   opts = opts or {}
   local id
   if opts.id then
      id = opts.id
      if ut.in_index() then
         current_index = api.nvim_win_get_cursor(0)[1]
      elseif on_display then
         for i, v in ipairs(on_display) do
            if v == id then
               current_index = i
            end
         end
      end
   elseif opts.row then
      current_index = opts.row
      id = on_display[current_index]
   elseif ut.in_index() then
      current_index = api.nvim_win_get_cursor(0)[1]
      id = on_display[current_index]
   elseif ut.in_entry() then
      id = on_display[current_index]
   else
      error("no context to show entry")
   end
   return DB[id], id
end

M.get_entry = get_entry

---Mark entry in db with read tag, if index rendered then grey out the entry
---@param id string
local function mark_read(id)
   DB:tag(id, "read")
   local buf = state.index.buf
   if buf and api.nvim_buf_is_valid(buf) then
      local NLine = Format.gen_nui_line(id, true)
      vim.bo[buf].modifiable = true
      NLine:render(buf, -1, current_index)
      vim.bo[buf].modifiable = false
   end
end

local function render_entry(ctx, lines, id, is_preview)
   local buf
   if ctx.buf and api.nvim_buf_is_valid(ctx.buf) then
      buf = ctx.buf
   else
      buf = api.nvim_create_buf(false, true)
   end

   vim.wo.winbar = nil
   vim.bo[buf].filetype = "markdown"
   vim.bo[buf].modifiable = true
   api.nvim_buf_set_lines(buf, 0, -1, false, {}) -- clear buf lines


   for i, v in ipairs(lines) do
      if type(v) == "table" then
         v:render(buf, -1, i)
      elseif type(v) == "string" then
         v = vim.trim(ut.unescape(v:gsub("\n", "")))
         api.nvim_buf_set_lines(buf, i - 1, i, false, { v })
      end
   end


   if not is_preview then
      local ok, urls = pcall(get_buf_urls, buf, current_entry.link)

      if not state.entry or not state.entry:valid() then
         state.entry = Win.new {
            buf = buf,
            b = {
               urls = ok and urls or {},
            },
            wo = Config.options.entry.wo,
            bo = Config.options.entry.bo,
            keys = {
               { "q", "close" },
               { "r", ":Feed urlview" },
            },
            ft = "markdown",
            autocmds = {
               [{ "BufEnter", "WinEnter", "VimResized" }] = function()
                  vim.o.cmdheight = 0
                  pcall(vim.cmd.colorscheme, Config.colorscheme)
               end,
               [{ "BufLeave", "WinLeave" }] = function()
                  vim.o.cmdheight = og.cmdheight
                  vim.cmd.colorscheme(og.colorscheme)
               end
            }
         }
      end

      local win = state.entry.win
      pcall(api.nvim_buf_set_name, buf, "FeedEntry")
      api.nvim_win_set_cursor(win, { 1, 0 })
      api.nvim_exec_autocmds("User", { pattern = "ShowEntryPost" })

      mark_read(id)
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

---@param ctx? { row: integer, id: string, buf: integer, link: string }
local function show_entry(ctx)
   ctx = ctx or {}
   local entry, id = get_entry(ctx)
   if not entry then
      return
   end
   current_entry = entry

   ---@alias entry_line NuiLine | string
   ---@type entry_line[]
   local lines = {}

   for i, v in ipairs({ "title", "author", "feed", "link", "date" }) do
      lines[i] = NuiLine({ NuiText(ut.capticalize(v) .. ": ", "FeedBold"), NuiText(Format[v](id)) })
   end
   table.insert(lines, "")

   if ctx.link then
      Markdown.convert(
         ctx.link,
         vim.schedule_wrap(function(markdown_lines)
            vim.list_extend(lines, entry_filter(markdown_lines))
            render_entry(ctx, lines, id, false)
         end)
      )
   elseif entry.content then
      Markdown.convert(
         entry.content(),
         vim.schedule_wrap(function(markdown_lines)
            vim.list_extend(lines, entry_filter(markdown_lines))
            render_entry(ctx, lines, id, ctx.buf ~= nil)
         end),
         true
      )
   else
      local markdown_lines = vim.split(ut.read_file(DB.dir .. "/data/" .. id), "\n")
      vim.list_extend(lines, entry_filter(markdown_lines))
      render_entry(ctx, lines, id, ctx.buf ~= nil)
   end
end

M.show_full    = function()
   local entry = get_entry()
   if entry and entry.link then
      show_entry({ link = entry.link })
   else
      vim.notify("no link to fetch")
   end
end

M.refresh      = function(opts)
   opts = opts or {}
   opts.show = vim.F.if_nil(opts.show, true)
   vim.g.feed_current_query = opts.query or vim.g.feed_current_query
   DB:update()
   on_display = DB:filter(vim.g.feed_current_query)
   if opts.show then
      local pos = ut.in_index() and api.nvim_win_get_cursor(0) or { 1, 0 }
      show_index()
      api.nvim_win_set_cursor(0, pos)
   end
   return on_display
end

M.quit         = function()
   if ut.in_index() then
      state.index:close()
      -- state.index = nil
   elseif ut.in_entry() then
      state.entry:close()
      -- state.entry = nil
   end
end

M.show_prev    = function()
   if current_index > 1 then
      show_entry({ row = current_index - 1 })
   end
end

M.show_next    = function()
   if current_index < #on_display then
      show_entry({ row = current_index + 1 })
   end
end

M.show_urls    = function()
   local urls = vim.b[state.entry.buf].urls
   Nui.select(urls, {
      prompt = "urlview",
      format_item = function(item)
         return item[1]
      end,
   }, function(item)
      if item then
         resolve_and_open(item[2], current_entry.link)
      end
   end)
end

M.open_url     = function()
   vim.cmd.normal("yi[") -- FIX:
   local text = vim.fn.getreg("0")
   local urls = vim.b[state.entry.buf].urls
   local item = vim.iter(urls):find(function(v)
      return v[1] == text
   end)
   local url = item and item[2] or vim.ui._get_urls()[1]
   if url then
      resolve_and_open(url, current_entry.link)
   end
end

M.show_browser = function()
   local entry, id = get_entry()
   if entry and entry.link then
      mark_read(id)
      vim.ui.open(entry.link)
   else
      ut.notify("show_in_browser", { msg = "no link for entry you try to open", level = "INFO" })
   end
end

M.show_log     = function()
   local str = ut.read_file(vim.fn.stdpath("data") .. "/feed.nvim.log")
   if str then
      Split("50%", vim.split(str, "\n"))
   end
end

M.show_hints   = function()
   local maps
   if ut.in_entry() then
      maps = Config.keys.entry
   elseif ut.in_index() then
      maps = Config.keys.index
   end

   local lines = {}
   for k, v in pairs(maps) do
      lines[#lines + 1] = v .. " -> " .. k
   end

   Split("30%", lines)
end

---Open split to show entry
---@param percentage any
M.show_split   = function(percentage)
   local _, id = get_entry()
   local split = Split(percentage or "50%")
   show_entry({ buf = split.bufnr, id = id })
end

---Open split to show feeds
---@param percentage string
M.show_feeds   = function(percentage)
   local split = Split(percentage or "50%")

   local nodes = {}

   local function kv(k, v)
      return string.format("%s: %s", k, v)
   end

   for _, url in ipairs(feedlist(feeds, false)) do
      local child = {}
      local feed = feeds[url]
      if feed and type(feed) == "table" then
         for k, v in pairs(feed) do
            child[#child + 1] = NuiTree.Node({ text = kv(k, vim.inspect(v)) })
         end
      end
      nodes[#nodes + 1] = NuiTree.Node({ text = feeds[url].title or url }, child or nil)
   end

   local tree = NuiTree({
      bufnr = split.bufnr,
      nodes = nodes,
   })

   split:map("n", "<Tab>", function()
      local node, _ = tree:get_node()
      if node and node:has_children() then
         if not node:is_expanded() then
            node:expand()
            tree:render()
         else
            node:collapse()
            tree:render()
         end
      end
   end, { noremap = true })

   tree:render()
end

---In Index: prompt for input and refresh
---Everywhere else: openk search backend
---@param q string
M.search       = function(q)
   local backend = ut.choose_backend(Config.search.backend)
   if q then
      M.refresh({ query = q })
   elseif ut.in_index() or not backend then
      Nui.input({ prompt = "Feed query: ", default = vim.g.feed_current_query .. " " }, function(val)
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
         ut.notify("opml", { msg = "failed to parse your opml file", level = "ERROR" })
      end
      DB:save_feeds()
   else
      ut.notify("opml", { msg = "failed to open your opml file", level = "ERROR" })
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
      ut.notify("commands", { msg = "failed to open your expert path", level = "INFO" })
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
   local coop = require "coop"
   if not url or not ut.looks_like_url(url) then
      return
   end
   coop.spawn(function()
      local ok = fetch.update_feed_co(url, { force = true })
      ut.notify("fetch", { msg = ut.url2name(url, feeds) .. (ok and " success" or " failed"), level = "INFO" })
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
   DB.feeds[url] = false
   DB:save_feeds()
end

M.show_winbar = require "feed.ui.bar"
M.show_index = show_index
M.show_entry = show_entry

---make

return M
