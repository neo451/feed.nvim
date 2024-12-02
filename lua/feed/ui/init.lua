local ut = require "feed.utils"
local db = ut.require "feed.db"
local format = require "feed.ui.format"
local urlview = require "feed.ui.urlview"
local config = require "feed.config"
local NuiText = require "nui.text"
local NuiLine = require "nui.line"
local health = require "feed.health"
local entities = require "feed.lib.entities"
local decode = entities.decode

-- TODO: grey out the entries just read, only hide after refresh
local function html_to_md(id)
   if not health.check_binary_installed { name = "pandoc", min_ver = 3 } then
      return "you need pandoc to view feeds https://pandoc.org"
   end
   local sourced_file = require("plenary.debug_utils").sourced_filepath()
   local filter = vim.fn.fnamemodify(sourced_file, ":h") .. "/pandoc_filter.lua"
   local cmd = {
      "pandoc",
      "-f",
      "html",
      "-t",
      filter,
      "--wrap=none",
      db.dir .. "/data/" .. id,
   }
   local obj = vim.system(cmd, { text = true }):wait()
   if obj.code ~= 0 then
      return "pandoc failed: " .. obj.stderr
   end
   return ut.unescape(obj.stdout)
end

local og_colorscheme = vim.g.colors_name
local on_display, current_index, urls, index
local query = config.search.default_query

local main_comp = vim.iter(config.layout)
   :filter(function(v)
      return not v.right
   end)
   :totable()

local extra_comp = vim.iter(config.layout)
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

providers.query = function()
   return query
end

providers.hints = function()
   return "<?> to show hints"
end

providers.lastUpdated = function() end

local function show_winbar()
   local comp = ut.comp
   local append = ut.append
   vim.wo.winbar = ""
   for _, v in ipairs(main_comp) do
      comp(v[1], providers[v[1]](v), v.width, v.color)
   end
   append "%="
   for _, v in ipairs(extra_comp) do
      comp(v[1], providers[v[1]](v), v.width, v.color)
   end
end

---@param buf integer
---@param entry feed.entry
---@param row integer
local function show_entry_info(buf, entry, row)
   local line = format.gen_nui_line(entry, main_comp) -- Nui
   line:render(buf, -1, row)
end

local function show_index()
   local buf = index or vim.api.nvim_create_buf(false, true)
   index = buf
   pcall(vim.api.nvim_buf_set_name, buf, "FeedIndex")
   on_display = on_display or db:filter(query)
   vim.bo[buf].modifiable = true
   for i, id in ipairs(on_display) do
      show_entry_info(buf, db[id], i)
   end
   vim.api.nvim_set_current_buf(buf)
   show_winbar()
   vim.api.nvim_exec_autocmds("User", { pattern = "ShowIndexPost" })
end

---@class feed.entry_opts
---@field row_idx? integer # will default to cursor row
---@field untag? boolean # default true
---@field id? string # db_id
---@field buf? integer # buffer to populate

---@param id string?
---@param row integer?
---@return feed.entry?
---@return string?
---@return integer?
local function get_entry(id, row)
   if id then
      return db[id], id, nil
   elseif row then
      id = on_display[row]
      return db[id], id, row
   elseif ut.in_index() then
      row = ut.get_cursor_row()
      id = on_display[row]
      return db[id], id, row
   elseif ut.in_entry() then
      local buf = vim.api.nvim_get_current_buf()
      row = vim.b[buf].row
      id = vim.b[buf].id
      return db[id], id, row
   end
end

local function kv(k, v)
   return string.format("%s: %s", k, v)
end

---@param opts? feed.entry_opts
local function show_entry(opts)
   opts = opts or {}
   local buf = opts.buf or vim.api.nvim_create_buf(false, true)
   pcall(vim.api.nvim_buf_set_name, buf, "FeedEntry")
   local untag = vim.F.if_nil(opts.untag, true)
   current_index = opts.row_idx or ut.get_cursor_row()
   local id = opts.id or on_display[current_index]
   local entry = db[id]
   if not entry then
      return
   end
   if untag then
      db:tag(id, "read")
   end

   ---@alias entry_line NuiLine | string
   ---@type entry_line[]
   local lines = {
      NuiLine { NuiText("Title: ", "title"), NuiText(decode(format.title(entry)), "") },
      NuiLine { NuiText("Author: ", "title"), NuiText(decode(entry.author), "") },
      NuiLine { NuiText("Feed: ", "title"), NuiText(decode(entry.feed), "") },
      NuiLine { NuiText("Link: ", "title"), NuiText(entry.link, "") },
      NuiLine { NuiText("Date: ", "title"), NuiText(format.date(entry), "") },
      "",
   }

   local entry_lines
   local md = html_to_md(id)
   entry_lines, urls = urlview(vim.split(md, "\n"), entry.link)
   vim.list_extend(lines, entry_lines)

   vim.bo[buf].modifiable = true
   for i, v in ipairs(lines) do
      if type(v) == "table" then
         v:render(buf, -1, i)
      elseif type(v) == "string" then
         vim.api.nvim_buf_set_lines(buf, i - 1, i, false, { v })
      end
   end

   if not opts.buf then
      vim.api.nvim_set_current_buf(buf)
   end
   vim.api.nvim_exec_autocmds("User", { pattern = "ShowEntryPost" })
end

--- TODO: register some state(tag/untag at leaset once) to tell refresh is needed, and then reset them, else do nothing
local function refresh(opts)
   opts = opts or {}
   opts.show = vim.F.if_nil(opts.show, true)
   if opts.query then
      query = opts.query
   end
   on_display = db:filter(opts.query)
   if opts.show then
      if index then
         vim.api.nvim_set_option_value("modifiable", true, { buf = index })
         for i = 1, vim.api.nvim_buf_line_count(0) do
            vim.api.nvim_buf_set_lines(index, i, i + 1, false, { "" })
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
   if ut.in_index() then
      vim.cmd "bd!"
      vim.api.nvim_exec_autocmds("User", { pattern = "QuitIndexPost" })
      restore_state()
   else
      vim.cmd "bd!"
      if index then
         vim.api.nvim_set_current_buf(index)
      end
      vim.api.nvim_exec_autocmds("User", { pattern = "QuitEntryPost" })
   end
end

local function show_prev()
   if current_index == 1 then
      return
   end
   show_entry { row_idx = current_index - 1 }
end

local function show_next()
   if current_index == #on_display then
      return
   end
   show_entry { row_idx = current_index + 1 }
end

local function show_urls()
   vim.ui.select(urls, {
      prompt = "urlview",
      format_item = function(item)
         return item[1]
      end,
   }, function(item)
      if item then
         if not ut.looks_like_url(item[2]) then
            ut.notify("urlview", { msg = "reletive link resolotion is to be implemented", level = "ERROR" })
         else
            vim.ui.open(item[2])
         end
      end
   end)
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
   local index = {
      { ".", "dot" },
      { "u", "undo" },
      { "<CR>", "show_entry" },
      { "<M-CR>", "show_in_split" },
      { "r", "refresh" },
      { "b", "show_in_browser" },
      { "s", "search" },
      { "y", "link_to_clipboard" },
      { "+", "tag" },
      { "-", "untag" },
      { "q", "quit" },
   }
   local entry = {
      { "b", "show_in_browser" },
      { "s", "search" },
      { "+", "tag" },
      { "-", "untag" },
      { "q", "quit" },
      { "r", "urlview" },
      { "}", "show_next" },
      { "{", "show_prev" },
      { "gx", "open_url" },
   }
   local maps
   if ut.in_entry() then
      maps = entry
   elseif ut.in_index() then
      maps = index
   end
   local Split = require "nui.split"
   local event = require("nui.utils.autocmd").event

   local split = Split {
      relative = "editor",
      position = "bottom",
      size = "30%",
   }
   local lines = {}
   for _, v in ipairs(maps) do
      lines[#lines + 1] = v[1] .. " -> " .. v[2]
   end
   vim.api.nvim_buf_set_lines(split.bufnr, 0, -1, false, lines)
   vim.api.nvim_set_option_value("number", false, { buf = split.winid })
   vim.api.nvim_set_option_value("relativenumber", false, { buf = split.winid })
   vim.api.nvim_set_option_value("modifiable", false, { buf = split.bufnr })

   split:mount()
   split:map("n", "q", function()
      split:unmount()
   end, { noremap = true })
   split:on(event.BufLeave, function()
      split:unmount()
   end)
end

local feeds = db.feeds
local function feedlist()
   return vim.iter(feeds)
      :filter(function(_, v)
         return type(v) == "table"
      end)
      :fold({}, function(acc, k)
         table.insert(acc, k)
         return acc
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

   vim.api.nvim_buf_set_lines(split.bufnr, 0, -1, false, lines)
   vim.api.nvim_set_option_value("number", false, { buf = split.winid })
   vim.api.nvim_set_option_value("relativenumber", false, { buf = split.winid })
   vim.api.nvim_set_option_value("modifiable", false, { buf = split.bufnr })

   local NuiTree = require "nui.tree"
   local nodes = {}
   for _, url in ipairs(feedlist()) do
      local child = {}
      if feeds[url] then
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

local function open_url()
   vim.cmd.normal "yi["
   local text = vim.fn.getreg "0"
   local item = vim.iter(urls):find(function(v)
      return v[1] == text
   end)
   if item then
      if not ut.looks_like_url(item[2]) then
         ut.notify("urlview", { msg = "reletive link resolotion is to be implemented", level = "ERROR" })
      else
         vim.ui.open(item[2])
      end
   end
end

local function show_browser()
   local entry = get_entry()
   if entry then
      local link = entry.link
      if link then
         -- M.untag.impl "unread"
         --- TODO: tag
         vim.ui.open(link)
      end
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
   open_url = open_url,
   quit = quit,
   refresh = refresh,
}
