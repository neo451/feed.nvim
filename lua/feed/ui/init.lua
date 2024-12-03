local ut = require "feed.utils"
---@type feed.db
local DB = ut.require "feed.db"
local Format = require "feed.ui.format"
local Config = require "feed.config"
local NuiText = require "nui.text"
local NuiLine = require "nui.line"
local NuiTree = require "nui.tree"
local Entities = require "feed.lib.entities"
local Markdown = require "feed.ui.markdown"
local Nui = require "feed.ui.nui"

local api = vim.api
local feeds = DB.feeds
local feedlist = ut.feedlist
local decode = Entities.decode

local og_colorscheme = vim.g.colors_name
local on_display, index
local urls = {}
local current_entry, current_index
local query = Config.search.default_query

local main_comp = vim.iter(Config.layout)
   :filter(function(v)
      return not v.right
   end)
   :totable()

-- local extra_comp = vim.iter(config.layout)
--    :filter(function(v)
--       return v.right
--    end)
--    :totable()

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
   return query
end

providers.hints = function()
   return "<?> to show hints"
end

providers.lastUpdated = function() end

local function show_winbar()
   local comp = ut.comp
   -- local append = ut.append
   vim.wo.winbar = ""
   for _, v in ipairs(main_comp) do
      comp(v[1], providers[v[1]](v), v.width, v.color)
   end
   -- append "%="
   -- for _, v in ipairs(extra_comp) do
   --    comp(v[1], providers[v[1]](v), v.width, v.color)
   -- end
end

-- TODO: just hijack the statusline when in show entry/index

local function show_index()
   local buf = index or api.nvim_create_buf(false, true)
   index = buf
   pcall(api.nvim_buf_set_name, buf, "FeedIndex")
   on_display = on_display or DB:filter(query)
   vim.bo[buf].modifiable = true
   for i, id in ipairs(on_display) do
      Format.gen_nui_line(DB[id], main_comp):render(buf, -1, i)
   end
   api.nvim_buf_set_lines(index, #on_display, #on_display + 1, false, { "" })
   api.nvim_set_current_buf(buf)
   show_winbar()
   api.nvim_exec_autocmds("User", { pattern = "ShowIndexPost" })
end

---@class feed.entry_opts
---@field row_idx? integer # will default to cursor row
---@field untag? boolean # default true
---@field id? string # db_id
---@field buf? integer # buffer to populate
---@field lines? string[]

---@return feed.entry
---@return string
local function get_entry()
   if ut.in_index() then
      local id = on_display[ut.get_cursor_row()]
      return DB[id], id
   end
   return current_entry, current_entry.id
end

local function grey_entry(id)
   if not index then
      return
   end
   local grey_comp = vim.deepcopy(main_comp)
   for _, v in ipairs(grey_comp) do
      v.color = "LspInlayHint"
   end
   local NLine = Format.gen_nui_line(DB[id], grey_comp)
   vim.bo[index].modifiable = true
   NLine:render(index, -1, current_index)
end

--- Returns all URLs in buffer, if any.
---@return string[][]
local function get_buf_urls()
   local buf = api.nvim_get_current_buf()
   vim.bo[buf].modifiable = true
   local cur_link = current_entry.link
   local ret = { { cur_link, cur_link } }

   local lang = "markdown_inline"
   local q = vim.treesitter.query.get(lang, "highlights")
   local tree = vim.treesitter.get_parser(buf, lang, {}):parse()[1]:root()
   if q then
      for _, match, metadata in q:iter_matches(tree, buf) do
         for id, nodes in pairs(match) do
            for _, node in ipairs(nodes) do
               local url = metadata[id] and metadata[id].url
               if url and match[url] then
                  for _, n in
                     ipairs(match[url] --[[@as TSNode[] ]])
                  do
                     local link = vim.treesitter.get_node_text(n, buf, { metadata = metadata[url] })
                     if node:type() == "inline_link" and node:child(1):type() == "link_text" then
                        ---@diagnostic disable-next-line: param-type-mismatch
                        local text = vim.treesitter.get_node_text(node:child(1), buf, { metadata = metadata[url] })
                        local row = node:child(1):range() + 1
                        ret[#ret + 1] = { text, link }
                        local sub_pattern = row .. "s/(" .. vim.fn.escape(link, "/") .. ")//g" -- TODO: add e flag in final
                        vim.cmd(sub_pattern)
                     elseif node:type() == "image" and node:child(2):type() == "image_description" then
                        local text = vim.treesitter.get_node_text(node:child(2), buf, { metadata = metadata[url] })
                        local row = node:child(1):range() + 1
                        ret[#ret + 1] = { text, link }
                        local sub_pattern = row .. "s/(" .. vim.fn.escape(link, "/") .. ")//g" -- TODO: add e flag in final
                        vim.cmd(sub_pattern)
                     else
                        ret[#ret + 1] = { link, link }
                     end
                  end
               end
            end
         end
      end
      vim.bo[buf].modifiable = false
   end
   return ret
end

---@param opts? feed.entry_opts
local function show_entry(opts)
   opts = opts or {}
   local buf = opts.buf or api.nvim_create_buf(false, true)
   api.nvim_buf_set_name(buf, "FeedEntry")
   local untag = vim.F.if_nil(opts.untag, true)
   current_index = opts.row_idx or ut.get_cursor_row()
   local id = opts.id or on_display[current_index]
   local entry = DB[id]
   current_entry = entry
   if not entry then
      return
   end
   if untag then
      DB:tag(id, "read")
      grey_entry(id)
   end
   local title = decode(Format.title(entry))
   local author = decode(entry.author)
   local feed = decode(entry.feed)
   local link = entry.link
   local date = Format.date(entry)

   ---@alias entry_line NuiLine | string
   ---@type entry_line[]
   local lines = {
      NuiLine { NuiText("Title: ", "title"), NuiText(title) },
      NuiLine { NuiText("Author: ", "title"), NuiText(author) },
      NuiLine { NuiText("Feed: ", "title"), NuiText(feed) },
      NuiLine { NuiText("Link: ", "title"), NuiText(link) },
      NuiLine { NuiText("Date: ", "title"), NuiText(date) },
      "",
   }

   local entry_lines = opts.lines or Markdown.convert(DB.dir .. "/data/" .. id)
   vim.list_extend(lines, entry_lines)

   vim.bo[buf].modifiable = true
   for i, v in ipairs(lines) do
      if type(v) == "table" then
         v:render(buf, -1, i)
      elseif type(v) == "string" then
         api.nvim_buf_set_lines(buf, i - 1, i, false, { v })
      end
   end

   if not opts.buf then
      api.nvim_set_current_buf(buf)
      api.nvim_exec_autocmds("User", { pattern = "ShowEntryPost" })
   end
   urls = get_buf_urls(buf)
end

local function show_full()
   local entry, id = get_entry()
   local buf = api.nvim_get_current_buf()
   if entry.link then
      vim.system({ "curl", entry.link }, { text = true }, function(res)
         vim.schedule(function()
            local temp = vim.fn.tempname()
            ut.save_file(temp, res.stdout)
            local lines = Markdown.convert(temp)
            show_entry { id = id, lines = lines, buf = buf }
         end)
      end)
   else
      print "no link to fetch"
   end
end

--- TODO: register some state(tag/untag at leaset once) to tell refresh is needed, and then reset them, else do nothing
local function refresh(opts)
   opts = opts or {}
   opts.show = vim.F.if_nil(opts.show, true)
   query = opts.query or query
   on_display = DB:filter(query)
   if opts.show then
      if index then
         api.nvim_set_option_value("modifiable", true, { buf = index })
         for i = 1, api.nvim_buf_line_count(0) do
            api.nvim_buf_set_lines(index, i, i + 1, false, { "" })
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
      api.nvim_buf_delete(index, { force = true })
      index = nil
      api.nvim_exec_autocmds("User", { pattern = "QuitIndexPost" })
      restore_state()
   elseif ut.in_entry() then
      api.nvim_buf_delete(0, { force = true })
      if index then
         api.nvim_set_current_buf(index)
         api.nvim_exec_autocmds("User", { pattern = "ShowIndexPost" })
      end
      api.nvim_exec_autocmds("User", { pattern = "QuitEntryPost" })
   end
end

local function show_prev()
   if current_index == 1 then
      return
   end
   show_entry { row_idx = current_index - 1, buf = api.nvim_get_current_buf() }
end

local function show_next()
   if current_index == #on_display then
      return
   end
   show_entry { row_idx = current_index + 1, buf = api.nvim_get_current_buf() }
end

local function resolve_and_open(url, base)
   if not ut.looks_like_url(url) then
      local link = ut.url_resolve(current_entry.link, url)
      if link then
         vim.ui.open(link)
      end
   else
      vim.ui.open(url)
   end
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
   local index = {
      { ".", "dot" },
      { "u", "undo" },
      { "<CR>", "show_entry" },
      { "<M-CR>", "show_in_split" },
      { "r", "refresh" },
      { "b", "show_browser" },
      { "s", "search" },
      { "y", "link_to_clipboard" },
      { "+", "tag" },
      { "-", "untag" },
      { "q", "quit" },
   }
   local entry = {
      { "b", "show_browser" },
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
   local entry, id = get_entry()
   if entry then
      local link = entry.link
      if link then
         -- db:tag(id, "read")
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
   show_full = show_full,
   open_url = open_url,
   quit = quit,
   refresh = refresh,
}
