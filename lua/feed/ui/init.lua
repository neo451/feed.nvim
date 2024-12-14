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
local Bar = require("feed.ui.bar")

local api = vim.api
local feeds = DB.feeds
local feedlist = ut.feedlist
local get_buf_urls = ut.get_buf_urls
local resolve_and_open = ut.resolve_and_open
local Split = Nui.split

local og_colorscheme = vim.g.colors_name
local og_cmdheight = vim.o.cmdheight
local on_display, index_buf
local urls = {}
local current_entry, current_index
local query = Config.search.default_query

local M = {}

local main_comp = vim.iter(Config.layout)
   :filter(function(v)
      return not v.right
   end)
   :totable()

local extra_comp = vim.iter(Config.layout)
   :filter(function(v)
      return v.right
   end)
   :totable()

local providers = {}

setmetatable(providers, {
   __index = function(_, k)
      return function()
         return ut.capticalize(k)
      end
   end,
})

providers.query = function()
   return "query: " .. query
end

-- TODO: needs to be auto updated
-- providers.progress = function()
--    current_index = current_index or 1
--    return ("[%d/%d]"):format(current_index, #on_display)
-- end

local function show_winbar()
   vim.wo.winbar = " "
   for i, v in ipairs(main_comp) do
      Bar.new_comp(v[1], providers[v[1]](v), (i == #main_comp) and 0 or v.width, v.color)
   end
   Bar.append("%=")
   for _, v in ipairs(extra_comp) do
      local text = providers[v[1]](v)
      Bar.new_comp(v[1], text, v.width, v.color)
   end
end

local function set_opts(opts, keys)
   local buf = vim.api.nvim_get_current_buf()
   local win = vim.api.nvim_get_current_win()
   vim.o.cmdheight = 0

   for rhs, lhs in pairs(keys) do
      vim.keymap.set("n", lhs, ("<cmd>Feed %s<cr>"):format(rhs), { buffer = buf, noremap = true })
   end
   for key, value in pairs(opts) do
      pcall(vim.api.nvim_set_option_value, key, value, { buf = buf })
      pcall(vim.api.nvim_set_option_value, key, value, { win = win })
   end
   if Config.colorscheme then
      vim.cmd.colorscheme(Config.colorscheme)
   end
end

local function show_index()
   og_colorscheme = vim.g.colors_name
   og_cmdheight = vim.o.cmdheight
   local buf = index_buf or api.nvim_create_buf(false, true)
   index_buf = buf
   pcall(api.nvim_buf_set_name, buf, "FeedIndex")
   on_display = on_display or DB:filter(query)
   vim.bo[buf].modifiable = true
   api.nvim_buf_set_lines(index_buf, 0, -1, false, {}) -- clear lines
   for i, id in ipairs(on_display) do
      Format.gen_nui_line(DB[id], main_comp):render(buf, -1, i)
   end
   api.nvim_buf_set_lines(index_buf, #on_display, #on_display + 1, false, { "" })
   api.nvim_set_current_buf(buf)
   show_winbar()
   set_opts(Config.options.index, Config.keys.index)
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
         current_index = ut.get_cursor_row()
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
      current_index = ut.get_cursor_row()
      id = on_display[current_index]
   elseif ut.in_entry() then
      id = on_display[current_index]
   else
      error("no context to show entry")
   end
   return DB[id], id
end

local function mark_read(id)
   if not index_buf then
      return
   end
   DB:tag(id, "read")
   local grey_comp = vim.deepcopy(main_comp)
   for _, v in ipairs(grey_comp) do
      v.color = "FeedRead"
   end
   local NLine = Format.gen_nui_line(DB[id], grey_comp)
   vim.bo[index_buf].modifiable = true
   NLine:render(index_buf, -1, current_index)
   vim.bo[index_buf].modifiable = false
end

local function render_entry(buf, lines, id, is_preview)
   vim.wo.winbar = nil
   vim.bo[buf].filetype = "markdown"
   vim.bo[buf].modifiable = true
   vim.api.nvim_buf_set_lines(buf, 0, -1, false, {}) -- clear buf lines

   for i, v in ipairs(lines) do
      if type(v) == "table" then
         v:render(buf, -1, i)
      elseif type(v) == "string" then
         v = v:gsub("\n", "")
         api.nvim_buf_set_lines(buf, i - 1, i, false, { v })
      end
   end

   if not is_preview then
      api.nvim_set_current_buf(buf)
      set_opts(Config.options.entry, Config.keys.entry)
      urls = get_buf_urls(buf, current_entry.link)
      if api.nvim_buf_get_name(buf) == "" then
         api.nvim_buf_set_name(buf, "FeedEntry")
      end
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
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
   if ctx.buf and not api.nvim_buf_is_valid(ctx.buf) then
      return
   end
   local buf = ctx.buf or M.entry_buf or api.nvim_create_buf(false, true)
   M.entry_buf = buf
   local entry, id = get_entry(ctx)
   if not entry then
      return
   end
   current_entry = entry

   ---@alias entry_line NuiLine | string
   ---@type entry_line[]
   local lines = {}

   for i, v in ipairs({ "title", "author", "feed", "link", "date" }) do
      lines[i] = NuiLine({ NuiText(ut.capticalize(v) .. ": ", "FeedBold"), NuiText(Format[v](entry)) })
   end
   table.insert(lines, "")

   if ctx.link then
      Markdown.convert(
         ctx.link,
         vim.schedule_wrap(function(markdown_lines)
            vim.list_extend(lines, entry_filter(markdown_lines))
            render_entry(buf, lines, id, false)
         end)
      )
      -- TODO: rethink
   elseif entry.content then
      Markdown.convert(
         entry.content(),
         vim.schedule_wrap(function(markdown_lines)
            vim.list_extend(lines, entry_filter(markdown_lines))
            render_entry(buf, lines, id, ctx.buf ~= nil)
         end),
         true
      )
   else
      local markdown_lines = vim.split(ut.read_file(DB.dir .. "/data/" .. id), "\n")
      vim.list_extend(lines, entry_filter(markdown_lines))
      render_entry(buf, lines, id, ctx.buf ~= nil)
   end
end

local function show_full()
   local entry = get_entry()
   if entry and entry.link then
      show_entry({ link = entry.link })
   else
      vim.notify("no link to fetch")
   end
end

--- TODO: register some state(tag/untag at leaset once) to tell refresh is needed, and then reset them, else do nothing
--- TODO: if not new query then just remove the greyed out lines
local function refresh(opts)
   opts = opts or {}
   opts.show = vim.F.if_nil(opts.show, true)
   query = opts.query or query
   on_display = DB:filter(query)
   if opts.show then
      show_index()
   end
   return on_display
end

local function quit()
   vim.o.cmdheight = og_cmdheight
   pcall(vim.cmd.colorscheme, og_colorscheme)
   if ut.in_index() then
      api.nvim_buf_delete(index_buf, { force = true })
      index_buf = nil
      api.nvim_exec_autocmds("User", { pattern = "QuitIndexPost" })
   elseif ut.in_entry() then
      api.nvim_buf_delete(0, { force = true })
      M.entry_buf = nil
      if index_buf then
         api.nvim_set_current_buf(index_buf)
         api.nvim_exec_autocmds("User", { pattern = "ShowIndexPost" })
         show_winbar()
      end
      api.nvim_exec_autocmds("User", { pattern = "QuitEntryPost" })
   end
end

local function show_prev()
   if current_index == 1 then
      return
   end
   show_entry({ row = current_index - 1 })
end

local function show_next()
   if current_index >= #on_display then
      return
   end
   show_entry({ row = current_index + 1 })
end

local function show_urls()
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

local function open_url()
   vim.cmd.normal("yi[") -- TODO: not ideal?
   local text = vim.fn.getreg("0")
   local item = vim.iter(urls):find(function(v)
      return v[1] == text
   end)
   local url = item and item[2] or vim.ui._get_urls()[1]
   if url then
      resolve_and_open(url, current_entry.link)
   end
end

local function show_browser()
   local entry, id = get_entry()
   if entry and entry.link then
      mark_read(id)
      vim.ui.open(entry.link)
   else
      ut.notify("show_in_browser", { msg = "no link for entry you try to open", level = "INFO" })
   end
end

local function show_log()
   local str = ut.read_file(vim.fn.stdpath("data") .. "/feed.nvim.log")
   if str then
      Split("50%", vim.split(str, "\n"))
   end
end

local function show_hints()
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
local function show_split(percentage)
   local _, id = get_entry()
   local split = Split(percentage or "50%")
   show_entry({ buf = split.bufnr, id = id })
end

---Open split to show feeds
---@param percentage string
local function show_feeds(percentage)
   local split = Split(percentage or "50%")

   local nodes = {}

   local function kv(k, v)
      return string.format("%s: %s", k, v)
   end

   for _, url in ipairs(feedlist(feeds)) do
      local child = {}
      if feeds[url] and type(feeds[url]) == "table" then
         for k, v in pairs(feeds[url]) do
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
local function search(q)
   local backend = ut.choose_backend(Config.search.backend)
   if q then
      refresh({ query = q })
   elseif ut.in_index() or not backend then
      vim.ui.input({ prompt = "Feed query: ", default = query .. " " }, function(val)
         if not val then
            return
         end
         refresh({ query = val })
      end)
   else
      local engine = require("feed.ui." .. backend)
      engine.feed_search()
      -- pcall(engine.feed_search)
   end
end

M.show_index = show_index
M.show_entry = show_entry
M.show_urls = show_urls
M.show_next = show_next
M.show_prev = show_prev
M.show_split = show_split
M.show_hints = show_hints
M.show_feeds = show_feeds
M.show_browser = show_browser
M.show_full = show_full
M.show_log = show_log
M.get_entry = get_entry
M.open_url = open_url
M.quit = quit
M.search = search
M.refresh = refresh

return M
