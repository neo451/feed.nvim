local Config = require("feed.config")
local Format = require("feed.ui.format")
local Markdown = require("feed.ui.markdown")
local Curl = require("feed.curl")
local Opml = require("feed.opml")
local Fetch = require("feed.fetch")
local Win = require("feed.ui.window")
local db = require("feed.db")
local ut = require("feed.utils")
local state = require("feed.ui.state")
local undo_history = state.undo_history
local redo_history = state.redo_history

local hl = vim.hl or vim.highlight
local api, fn, fs = vim.api, vim.fn, vim.fs

local og = {}

local M = {
   state = state,
}

M = vim.tbl_extend("keep", M, require("feed.ui.componants"))
M = vim.tbl_extend("keep", M, require("feed.ui.bar"))

local ns = api.nvim_create_namespace("feed_index")
local ns_read = api.nvim_create_namespace("feed_index_read")
local ns_entry = api.nvim_create_namespace("feed_entry")

---get entry base on current context, and update current_index
---@return feed.entry?
---@return string?
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
      error("no context to show entry")
   end
   if id then
      return db[id], id
   end
end

---Mark entry in db with read tag, if index rendered then grey out the entry
---@param id string
local function mark_read(id)
   db:tag(id, "read")
   if state.index and state.index:valid() then
      local buf = state.index.buf
      api.nvim_buf_clear_namespace(buf, ns, state.cur - 1, state.cur)
      hl.range(buf, ns_read, "FeedRead", { state.cur - 1, 0 }, { state.cur - 1, -1 })
   end
end

---@param buf number
local function image_attach(buf)
   if not Snacks then
      vim.notify("Snacks is not available")
      return
   end
   local ok, f = pcall(Snacks.image.doc.inline, buf)
   return ok and f and pcall(f)
end

local body_transforms = {
   require("feed.utils").remove_urls,
   -- TODO: get rid of html headers and stuff
   -- TODO: allow user
}

---@param buf integer
---@param body string
---@param id string
local function render_entry(buf, body, id)
   if not api.nvim_buf_is_valid(buf) then
      return
   end
   vim.bo[buf].modifiable = true
   api.nvim_buf_set_lines(buf, 0, -1, false, {}) -- clear buf lines

   local header = {}
   for i, v in ipairs({ "title", "author", "feed", "link", "date" }) do
      header[i] = ut.capticalize(v) .. ": " .. Format[v](id, db)
   end

   local urls = ut.get_urls(body, db[id].link)
   if urls then
      state.urls = urls
   else
      if vim.g.feed_debug then
         vim.notify("get_urls failed for string: " .. body)
      end
   end

   local ok, res

   for _, f in ipairs(body_transforms) do
      ok, res = pcall(f, body, id)
      if ok then
         body = res
      end
   end

   header[#header + 1] = ""

   local lines = vim.list_extend(header, vim.split(body, "\n"))

   for i, v in ipairs(lines) do
      api.nvim_buf_set_lines(buf, i - 1, i, false, { v })
   end

   for i, t in ipairs({
      { 7, "FeedTitle" },
      { 8, "FeedAuthor" },
      { 6, "FeedFeed" },
      { 6, "FeedLink" },
      { 6, "FeedDate" },
   }) do
      local j, hi = t[1], t[2]
      hl.range(buf, ns_entry, hi, { i - 1, j }, { i - 1, 200 })
   end
   vim.bo[buf].modifiable = false

   image_attach(buf)
   mark_read(id)

   api.nvim_buf_set_name(buf, "FeedEntry")

   api.nvim_exec_autocmds("User", {
      pattern = "FeedShowEntry",
   })
end

local function hl_index(buf)
   for linenr = 1, #state.entries do
      local acc = 0
      local layout = Config.layout
      for _, name in ipairs(layout.order) do
         local sect = layout[name]
         local width = sect.width or 100
         local byte_start, byte_end = ut.display_to_byte_range(buf, linenr, acc, acc + width)
         hl.range(buf, ns, sect.color, { linenr - 1, byte_start }, { linenr - 1, byte_end })
         acc = acc + width + 1
      end
   end
end

M.show_index = function()
   local cursor_pos, scroll_pos
   if state.index then
      cursor_pos = api.nvim_win_get_cursor(state.index.win)
      scroll_pos = fn.line("w0")
   else
      state.index = Win.new({
         wo = Config.options.index.wo,
         bo = Config.options.index.bo,
         keys = Config.keys.index,
         zindex = 3,
      })
   end

   local buf, win = state.index.buf, state.index.win
   vim.wo[win].winbar = M.show_winbar()
   api.nvim_buf_set_name(buf, "FeedIndex")
   state.entries = state.entries or db:filter(state.query)
   vim.bo[buf].modifiable = true
   api.nvim_buf_set_lines(buf, 0, -1, false, {}) -- clear lines

   local lines = {}
   for i, id in ipairs(state.entries) do
      lines[i] = Format.entry(id, Config.layout, db)
   end
   table.insert(lines, "")
   api.nvim_buf_set_lines(buf, 0, -1, false, lines)
   hl_index(buf)
   vim.bo[buf].modifiable = false

   if cursor_pos and scroll_pos then
      pcall(api.nvim_win_set_cursor, win, cursor_pos)
      fn.winrestview({ topline = scroll_pos })
   end

   api.nvim_exec_autocmds("User", {
      pattern = "FeedShowIndex",
   })
end

---@param ctx? { row: integer, id: string, buf: integer, link: string, read: boolean }
M.preview_entry = function(ctx)
   ctx = ctx or {}
   local entry, id = get_entry(ctx)
   if not entry or not id then
      return
   end

   local buf
   if ctx.buf and api.nvim_buf_is_valid(ctx.buf) then
      buf = ctx.buf
   else
      buf = api.nvim_create_buf(false, true)
   end

   Markdown.convert({
      fp = tostring(db.dir / "data" / id),
      cb = function(body)
         render_entry(buf, body, id)
      end,
   })
end

---@param ctx? { row: integer, id: string, buf: integer, link: string }
local function show_entry(ctx)
   ctx = ctx or {}
   local entry, id = get_entry(ctx)
   if not entry or not id then
      return
   end

   local buf
   if ctx.buf and api.nvim_buf_is_valid(ctx.buf) then
      buf = ctx.buf
   else
      buf = api.nvim_create_buf(false, true)
   end

   state.entry = Win.new({
      prev_win = state.index and state.index.win or nil,
      buf = buf,
      wo = Config.options.entry.wo,
      bo = Config.options.entry.bo,
      keys = Config.keys.entry,
      ft = "markdown",
      zen = Config.zen.enabled,
      zindex = 5,
   })

   if ctx.link then
      Markdown.convert({
         link = ctx.link,
         cb = function(body)
            render_entry(buf, body, id)
         end,
      })
   elseif entry.content then
      Markdown.convert({
         src = entry.content(),
         cb = function(body)
            render_entry(buf, body, id)
         end,
      })
   else
      Markdown.convert({
         fp = tostring(db.dir / "data" / id),
         cb = function(body)
            render_entry(buf, body, id)
         end,
      })
   end
end

M.quit = function()
   if ut.in_index() then
      state.index:close()
      state.index = nil
      vim.api.nvim_exec_autocmds("User", {
         pattern = "FeedQuitIndex",
      })
   elseif ut.in_entry() then
      state.entry:close()
      state.entry = nil
      vim.api.nvim_exec_autocmds("User", {
         pattern = "FeedQuitEntry",
      })
   end
end

M.show_full = function()
   local entry = get_entry()
   if entry and entry.link then
      api.nvim_exec_autocmds("ExitPre", { buffer = state.entry.buf })
      show_entry({ link = entry.link, buf = state.entry.buf })
      api.nvim_exec_autocmds("BufWritePost", {})
   else
      vim.notify("no link to fetch")
   end
end

M.show_prev = function()
   if state.cur > 1 then
      api.nvim_exec_autocmds("ExitPre", { buffer = state.entry.buf })
      M.preview_entry({ row = state.cur - 1, buf = state.entry.buf })
      api.nvim_exec_autocmds("BufWritePost", {})
   end
end

M.show_next = function()
   if state.cur < #state.entries then
      api.nvim_exec_autocmds("ExitPre", { buffer = state.entry.buf })
      M.preview_entry({ row = state.cur + 1, buf = state.entry.buf })
      api.nvim_exec_autocmds("BufWritePost", {})
   end
end

M.show_urls = function()
   M.select(state.urls, {
      prompt = "urlview",
      format_item = function(item)
         return item[1]
      end,
   }, function(item)
      if item then
         vim.ui.open(item[2])
      end
   end)
end

M.show_browser = function()
   local entry, id = get_entry()
   if id and entry and entry.link then
      mark_read(id)
      vim.ui.open(entry.link)
   else
      vim.notify("no link for entry you try to open")
   end
end

M.show_log = function()
   local str = ut.read_file(fn.stdpath("data") .. "/feed.nvim.log") or ""
   M.split({}, "50%", vim.split(str, "\n"))
end

M.show_hints = function()
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
      if type(k) == "string" then
         lines[#lines + 1] = v .. " -> " .. k
      end
   end

   M.split({
      wo = {
         winbar = "%#Title# Key Hints",
      },
   }, "50%", lines)
end

---Open split to show entry
---@param percentage any
M.show_split = function(percentage)
   local _, id = get_entry()
   assert(id)
   local split = M.split({}, percentage or "50%")
   M.preview_entry({ buf = split.buf, id = id, read = true })
   ut.wo(split.win, Config.options.entry.wo)
   ut.bo(split.buf, Config.options.entry.bo)
end

M.show_feeds = function(percentage)
   local split = M.split({
      wo = {
         spell = false,
         winbar = "%#Title# Feedlist: <cr> to toggle fold",
      },
      bo = {
         filetype = "markdown",
      },
      autocmds = {
         BufLeave = function(self)
            self:close()
         end,
      },
   }, percentage or "50%", {})

   local function node_to_md(heading, url, items)
      local res = {}
      res[#res + 1] = "# " .. heading
      if items.desc then
         res[#res + 1] = string.gsub(items.desc, "\n", "")
      end
      items.desc = nil
      items.title = nil
      for k, v in pairs(items) do
         res[#res + 1] = ("- %s: `%s`"):format(k, string.gsub((type(v) == "table" and vim.inspect(v) or v), "\n", ""))
      end
      res[#res + 1] = ("- xmlUrl: `%s`"):format(url)
      res[#res + 1] = ""
      return res
   end

   local lines = {}

   db:update()
   for url, feed in pairs(db.feeds) do
      if type(feed) == "table" then
         lines = vim.list_extend(lines, node_to_md(feed.title or url, url, feed))
      end
   end

   api.nvim_buf_set_lines(split.buf, 0, -1, false, lines)

   vim.wo[split.win].foldmethod = "expr"
   vim.wo[split.win].foldlevel = 0
   vim.wo[split.win].foldexpr = "v:lua.vim.treesitter.foldexpr()"
   vim.wo[split.win].foldtext = ""
   vim.wo[split.win].fillchars = "foldopen:,foldclose:,fold: ,foldsep: "

   vim.keymap.set("n", "<cr>", "zA", { buffer = split.buf })
   vim.bo[split.buf].modifiable = false
end

M.load_opml = function(path)
   local str
   if ut.looks_like_url(path) then
      str = Curl.get(path, {}).stdout -- FIXME:
   else
      path = fs.normalize(path)
      str = ut.read_file(path)
   end
   if not str then
      vim.notify("failed to open your opml file")
   end

   local outlines = Opml.import(str)
   if outlines then
      for k, v in pairs(outlines) do
         db.feeds[k] = v
      end
   else
      vim.notify("failed to parse your opml file")
   end
   db:save_feeds()
end

M.export_opml = function(fp)
   fp = fs.normalize(fp)
   local str = Opml.export(db.feeds)
   local ok = ut.save_file(fp, str)
   if not ok then
      vim.notify("failed to export your opml file")
   end
end

--- FIXME
M.dot = function()
   vim.notify("No operation defined for dot")
end

M.undo = function()
   local act = table.remove(undo_history, #undo_history)
   if not act then
      vim.notify("Already at the oldest change")
      return
   end
   if act.type == "tag" then
      M.untag(act.tag, act.id, false)
      table.insert(redo_history, act)
   elseif act.type == "untag" then
      M.tag(act.tag, act.id, false)
      table.insert(redo_history, act)
   elseif act.type == "search" then
      table.insert(redo_history, { type = "search", query = state.query })
      M.refresh(act.query, false)
   end
end

M.redo = function()
   local act = table.remove(redo_history, #redo_history)
   if not act then
      vim.notify("Already at the newst change")
      return
   end
   if act.type == "untag" then
      M.untag(act.tag, act.id)
   elseif act.type == "tag" then
      M.tag(act.tag, act.id)
   elseif act.type == "search" then
      M.refresh(act.query)
   end
end

M.tag = function(t, id, save)
   save = vim.F.if_nil(save, true)
   id = id or select(2, get_entry())
   if not t or not id then
      return
   end
   db:tag(id, t)
   if ut.in_index() then
      M.refresh()
   end
   M.dot = function()
      M.tag(t)
   end
   if save then
      table.insert(undo_history, { type = "tag", tag = t, id = id })
   end
end

M.untag = function(t, id, save)
   save = vim.F.if_nil(save, true)
   id = id or select(2, get_entry())
   if not t or not id then
      return
   end
   db:untag(id, t)
   if ut.in_index() then
      M.refresh()
   end
   M.dot = function()
      M.untag(t)
   end
   if save then
      table.insert(undo_history, { type = "untag", tag = t, id = id })
   end
end

---@param query string?
M.refresh = function(query, save)
   save = vim.F.if_nil(save, true)
   if query and save then
      table.insert(undo_history, { type = "search", query = state.query })
   end
   state.query = query or state.query
   state.entries = db:filter(state.query)
   M.show_index()
end

---In Index: prompt for input and refresh
---Everywhere else: openk search backend
---@param q string
M.search = function(q)
   local backend = ut.choose_backend(Config.search.backend)
   if q then
      M.refresh(q)
   elseif ut.in_index() or not backend then
      M.input({
         prompt = "Search: ",
         default = state.query,
      }, function(input)
         if not input then
            return
         end
         M.refresh(input)
      end)
   else
      local engine = require("feed.ui." .. backend)
      engine.feed_search()
   end
end

-- TODO: support argument
M.grep = function()
   local backend = ut.choose_backend(Config.search.backend)
   local engine = require("feed.ui." .. backend)
   engine.feed_grep()
end

---@param url string
M.update_feed = function(url)
   local Coop = require("coop")
   local copcall = require("coop.coroutine-utils").copcall

   if not url or not ut.looks_like_url(url) then
      return
   end
   Coop.spawn(function()
      local ok, res = copcall(Fetch.update_feed_co, url, { force = true })
      if not ok then
         vim.notify(ut.url2name(url, db.feeds) .. (ok and " success" or " failed") .. ": " .. res)
      end
   end)
end

M.show_entry = show_entry
M.get_entry = get_entry

return M
