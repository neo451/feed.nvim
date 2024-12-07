local ut = require "feed.utils"
---@type feed.db
local DB = require "feed.db"
local Format = require "feed.ui.format"
local Config = require "feed.config"
local NuiText = require "nui.text"
local NuiLine = require "nui.line"
local NuiTree = require "nui.tree"
local Markdown = require "feed.ui.markdown"
local Nui = require "feed.ui.nui"
local Bar = require "feed.ui.bar"

local api = vim.api
local feeds = DB.feeds
local feedlist = ut.feedlist
local get_buf_urls = ut.get_buf_urls
local resolve_and_open = ut.resolve_and_open

local og_colorscheme = vim.g.colors_name
local on_display, index_buf, entry_buf
local urls = {}
local current_entry, current_index
local query = Config.search.default_query

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
         return string.upper(k:sub(0, 1)) .. k:sub(2, -1)
      end
   end,
})

--- TODO: put these into statusline
providers.query = function()
   return " query: " .. query
end

-- TODO: needs to be auto updated
-- providers.progress = function()
--    current_index = current_index or 1
--    return ("[%d/%d]"):format(current_index, #on_display)
-- end

local function show_winbar()
   vim.wo.winbar = ""
   for i, v in ipairs(main_comp) do
      Bar.new_comp(v[1], providers[v[1]](v), (i == #main_comp) and 0 or v.width, v.color)
   end
   Bar.append "%="
   for _, v in ipairs(extra_comp) do
      local text = providers[v[1]](v)
      Bar.new_comp(v[1], text, v.width, v.color)
   end
end

local function show_index()
   local buf = index_buf or api.nvim_create_buf(false, true)
   index_buf = buf
   pcall(api.nvim_buf_set_name, buf, "FeedIndex")
   on_display = on_display or DB:filter(query)
   vim.bo[buf].modifiable = true
   for i, id in ipairs(on_display) do
      Format.gen_nui_line(DB[id], main_comp):render(buf, -1, i)
   end
   api.nvim_buf_set_lines(index_buf, #on_display, #on_display + 1, false, { "" })
   api.nvim_set_current_buf(buf)
   show_winbar()
   api.nvim_exec_autocmds("User", { pattern = "ShowIndexPost" })
end

---@return feed.entry?
---@return string?
local function get_entry(opts)
   opts = opts or {}
   local id
   if opts.id then
      id = opts.id
      if ut.in_index() then
         current_index = ut.get_cursor_row()
      else
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
      error "no context to show entry"
   end
   return DB[id], id
end

local function grey_entry(id)
   if not index_buf then
      return
   end
   local grey_comp = vim.deepcopy(main_comp)
   for _, v in ipairs(grey_comp) do
      v.color = "LspInlayHint"
   end
   local NLine = Format.gen_nui_line(DB[id], grey_comp)
   vim.bo[index_buf].modifiable = true
   NLine:render(index_buf, -1, current_index)
end

local function render_entry(buf, lines, id, is_preview)
   if not api.nvim_buf_is_valid(buf) then
      return
   end
   vim.bo[buf].modifiable = true
   for i, v in ipairs(lines) do
      if type(v) == "table" then
         v:render(buf, -1, i)
      elseif type(v) == "string" then
         api.nvim_buf_set_lines(buf, i - 1, i, false, { v })
      end
   end

   if not is_preview then
      api.nvim_set_current_buf(buf)
      api.nvim_exec_autocmds("User", { pattern = "ShowEntryPost" })
      DB:tag(id, "read")
      grey_entry(id)
      urls = get_buf_urls(buf, current_entry.link)
      pcall(api.nvim_buf_set_name, buf, "FeedEntry")
   end
end

---@class feed.entry_opts
---@field row? integer  default to cursor row
---@field id? string  db_id
---@field buf? integer  buffer to populate
---@field fp? string  path to raw html

---temparay solution for getting rid of junks and get clean markdown
---@param lines string[]
---@return string[]
local function entry_filter(lines)
   local idx
   local res = {}
   for i, v in ipairs(lines) do
      if v:find "^# " or v:find "^## " then
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

local function capticalize(str)
   return str:sub(1, 1):upper() .. str:sub(2)
end

---@param opts? feed.entry_opts
local function show_entry(opts)
   opts = opts or {}
   if opts.buf and not api.nvim_buf_is_valid(opts.buf) then
      return
   end
   local buf = opts.buf or entry_buf or api.nvim_create_buf(false, true)
   entry_buf = buf
   local entry, id = get_entry(opts)
   if not entry then
      return
   end
   current_entry = entry

   ---@alias entry_line NuiLine | string
   ---@type entry_line[]
   local lines = {}

   for i, v in ipairs { "title", "author", "feed", "link", "date" } do
      lines[i] = NuiLine { NuiText(capticalize(v) .. ": ", "title"), NuiText(Format[v](entry)) }
   end
   table.insert(lines, "")
   vim.wo.winbar = nil

   Markdown.convert(
      opts.fp or DB.dir .. "/data/" .. id,
      vim.schedule_wrap(function(markdown_lines)
         vim.list_extend(lines, entry_filter(markdown_lines))
         render_entry(buf, lines, id, opts.buf ~= nil)
      end)
   )
end

local function show_full()
   local entry = get_entry()
   if entry and entry.link then
      vim.schedule(function()
         show_entry { fp = entry.link }
      end)
   else
      vim.notify "no link to fetch"
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
      if index_buf then
         api.nvim_set_option_value("modifiable", true, { buf = index_buf })
         for i = 1, api.nvim_buf_line_count(0) do
            api.nvim_buf_set_lines(index_buf, i, i + 1, false, { "" })
         end
      end
      show_index()
      ut.trim_last_lines()
   end
   return on_display
end

local function restore_state()
   vim.cmd "set cmdheight=1"
   vim.wo.winbar = "" -- TODO: restore the user's old winbar is there is
   pcall(vim.cmd.colorscheme, og_colorscheme)
end

local function quit()
   restore_state()
   if ut.in_index() then
      api.nvim_buf_delete(index_buf, { force = true })
      index_buf = nil
      api.nvim_exec_autocmds("User", { pattern = "QuitIndexPost" })
   elseif ut.in_entry() then
      api.nvim_buf_delete(0, { force = true })
      entry_buf = nil
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
   show_entry { row = current_index - 1, buf = api.nvim_get_current_buf() }
end

local function show_next()
   if current_index == #on_display then
      return
   end
   show_entry { row = current_index + 1, buf = api.nvim_get_current_buf() }
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
   vim.cmd.normal "yi[" -- TODO: not ideal?
   local text = vim.fn.getreg "0"
   local item = vim.iter(urls):find(function(v)
      return v[1] == text
   end)
   local url = item and item[2] or vim.ui._get_urls()[1]
   if url then
      resolve_and_open(url, current_entry.link)
   end
end

local function show_split()
   local Split = require "nui.split"
   local event = require("nui.utils.autocmd").event
   local _, id = get_entry()

   local split = Split {
      relative = "editor",
      position = "bottom",
      size = "50%",
   }

   split:mount()
   split:map("n", "q", function()
      split:unmount()
   end, { noremap = true })
   show_entry { buf = split.bufnr, id = id }
   split:on(event.BufLeave, function()
      split:unmount()
   end)
end

local function show_hints()
   local maps
   if ut.in_entry() then
      maps = Config.keys.entry
   elseif ut.in_index() then
      maps = Config.keys.index
   end
   local Split = require "nui.split"
   local event = require("nui.utils.autocmd").event

   local split = Split {
      relative = "editor",
      position = "bottom",
      size = "30%",
   }
   local lines = {}
   for k, v in pairs(maps) do
      lines[#lines + 1] = v .. " -> " .. k
   end
   api.nvim_buf_set_lines(split.bufnr, 0, -1, false, lines)
   api.nvim_set_option_value("number", false, { buf = split.winid })
   api.nvim_set_option_value("relativenumber", false, { buf = split.winid })
   api.nvim_set_option_value("modifiable", false, { buf = split.bufnr })

   split:mount()
   split:map("n", "q", function()
      split:unmount()
   end, { noremap = true })
   split:on(event.BufLeave, function()
      split:unmount()
   end)
end

local function show_feeds()
   local Split = require "nui.split"
   local event = require("nui.utils.autocmd").event

   local split = Split {
      relative = "editor",
      position = "bottom",
      size = "40%",
   }
   local lines = {}

   api.nvim_buf_set_lines(split.bufnr, 0, -1, false, lines)
   api.nvim_set_option_value("number", false, { buf = split.winid })
   api.nvim_set_option_value("relativenumber", false, { buf = split.winid })
   api.nvim_set_option_value("modifiable", false, { buf = split.bufnr })

   local nodes = {}

   local function kv(k, v)
      return string.format("%s: %s", k, v)
   end

   for _, url in ipairs(feedlist(feeds)) do
      local child = {}
      if feeds[url] and type(feeds[url]) == "table" then
         for k, v in pairs(feeds[url]) do
            child[#child + 1] = NuiTree.Node { text = kv(k, vim.inspect(v)) }
         end
      end
      nodes[#nodes + 1] = NuiTree.Node({ text = feeds[url].title or url }, child or nil)
   end

   local tree = NuiTree {
      bufnr = split.bufnr,
      nodes = nodes,
   }

   tree:render()

   split:mount()
   split:map("n", "q", function()
      split:unmount()
   end, { noremap = true })
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
   split:on(event.BufLeave, function()
      split:unmount()
   end)
end

local function show_browser()
   local entry, _ = get_entry()
   if entry and entry.link then
      -- db:tag(id, "read")
      vim.ui.open(entry.link)
   else
      ut.notify("show_in_browser", { msg = "no link for entry you try to open", level = "INFO" })
   end
end

-- TODO: full text fetch if entry is empty

return {
   show_index = show_index,
   get_entry = get_entry,
   show_entry = show_entry,
   show_urls = show_urls,
   show_next = show_next,
   show_prev = show_prev,
   show_split = show_split,
   show_hints = show_hints,
   show_feeds = show_feeds,
   show_browser = show_browser,
   show_full = show_full,
   open_url = open_url,
   quit = quit,
   refresh = refresh,
}
