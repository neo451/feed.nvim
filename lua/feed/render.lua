-- TODO: grey out the entries just read, only hide after refresh

local db = require("feed.db").new()
local ut = require "feed.utils"
local format = require "feed.format"
local urlview = require "feed.urlview"
local config = require "feed.config"
local date = require "feed.date"

local align = ut.align

local og_colorscheme, og_buffer, og_winbar

local M = {
   on_display = nil,
   query_history = {},
   state = {
      query = config.search.default_query,
      in_split = false,
      indexed_once = false,
   },
}

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
   return M.state.query
end

providers.lastUpdated = function() end

---@param lines string[]
---@param buf integer
local function show(lines, buf)
   vim.bo[buf].modifiable = true
   vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
   vim.api.nvim_set_current_buf(buf)
end

local NuiText = require "nui.text"

---@param buf integer
---@param text string
---@param hi_grp string
---@param col integer
---@param row integer
local function render_text(buf, text, hi_grp, col, row)
   local obj = NuiText(text, hi_grp)
   obj:render_char(buf, -1, row, col)
end

local function render_line(buf, entry, row)
   vim.api.nvim_buf_set_lines(buf, row - 1, row, false, { "" })
   local acc_width = 0
   for _, v in ipairs(main_comp) do
      local text = entry[v[1]] or ""
      if v[1] == "tags" then
         text = format.tags(entry.tags)
      elseif v[1] == "feed" then
         if db.feeds[entry.feed] then
            text = db.feeds[entry.feed].title
         else
            text = entry.feed
         end
      elseif v[1] == "date" then
         text = date.new_from.number(entry.time):format(config.date_format)
      end
      text = align(text, v.width, v.right_justify) .. " "
      render_text(buf, text, v.color, acc_width, row)
      acc_width = acc_width + v.width + 1
   end
end

function M.show_index(opts)
   opts = vim.F.if_nil(opts, {})
   og_colorscheme = vim.g.colors_name
   og_buffer = vim.api.nvim_get_current_buf()
   og_winbar = vim.wo.winbar
   M.show_winbar()
   if M.state.indexed_once and not opts.refresh then
      vim.api.nvim_set_current_buf(M.state.index_buf)
      vim.api.nvim_exec_autocmds("User", {
         pattern = "ShowIndexPost",
      })
      return
   end
   if not M.on_display then
      M.on_display = db:filter(M.state.query)
   end
   if not M.state.index_buf then
      M.state.index_buf = vim.api.nvim_create_buf(false, true)
   end
   vim.bo[M.state.index_buf].modifiable = true
   for i, id in ipairs(M.on_display) do
      local entry = db[id]
      render_line(M.state.index_buf, entry, i)
   end
   vim.api.nvim_set_current_buf(M.state.index_buf)
   M.show_winbar()
   M.state.indexed_once = true
   vim.api.nvim_exec_autocmds("User", {
      pattern = "ShowIndexPost",
   })
end

---@param opts? feed.entry_opts
function M.show_entry(opts)
   opts = opts or {}
   local untag = vim.F.if_nil(opts.untag, true)
   local entry, id, row = M.get_entry(opts)
   if not entry or not id then
      return
   end
   if row then
      M.current_index = row
   end
   if untag then
      entry.tags.unread = nil
      db:save_entry(id)
   end
   local raw_str = db:read_entry(id)
   if raw_str then
      local lines, urls = urlview(vim.split(raw_str, "\n"))
      M.state.urls = urls
      if not M.state.entry_buf then
         M.state.entry_buf = vim.api.nvim_create_buf(false, true)
      end
      show(lines, M.state.entry_buf)
      M.show_winbar()
      vim.api.nvim_exec_autocmds("User", {
         pattern = "ShowEntryPost",
      })
   end
end

function M.show_winbar()
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

---@param opts? feed.entry_opts
---@return feed.entry?
---@return string?
---@return integer?
function M.get_entry(opts)
   local buf = vim.api.nvim_get_current_buf()
   opts = opts or {}
   if opts.id then
      return db[opts.id], opts.id, nil
   end
   local row
   if opts.row_idx then
      row = opts.row_idx
   elseif buf == M.state.entry_buf or M.state.in_split then
      row = M.current_index
   elseif buf == M.state.index_buf then
      row = ut.get_cursor_row()
   else
      return nil, nil, nil
   end
   local id = M.on_display[row]
   return db[id], id, row
end

function M.refresh()
   M.on_display = db:filter(M.state.query)
   M.show_index { refresh = true }
end

function M.quit()
   local buf = vim.api.nvim_get_current_buf()
   if M.state.in_split then
      vim.cmd "q"
      vim.api.nvim_set_current_buf(M.state.index_buf)
      M.state.in_split = false
   elseif M.state.entry_buf == buf then
      M.show_index()
      vim.api.nvim_exec_autocmds("User", {
         pattern = "QuitEntryPost",
      })
   elseif M.state.index_buf == buf then
      if not og_buffer then
         og_buffer = vim.api.nvim_create_buf(true, false)
      end
      vim.api.nvim_set_current_buf(og_buffer)
      pcall(vim.cmd.colorscheme, og_colorscheme)
      vim.api.nvim_exec_autocmds("User", {
         pattern = "QuitIndexPost",
      })
   end
end

return M
