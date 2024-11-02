local M = {}
local index_rendered = false

---@type table<string, any>
M.state = {
   in_split = false,
   on_display = {},
   query_history = {},
}

local db = require "feed.db"
local ut = require "feed.utils"
local format = require "feed.format"
local search = require "feed.search"
local urlview = require "feed.urlview"

function M.prepare_bufs()
   if M.buf then
      return
   end
   M.buf = {}
   M.buf.index = vim.api.nvim_create_buf(false, true)
   M.buf.entry = vim.api.nvim_create_buf(false, true)
end

---@param lines string[]
---@param buf integer
function M.show(lines, buf)
   vim.bo[buf].modifiable = true
   vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
   vim.api.nvim_set_current_buf(buf)
end

function M.show_index(opts)
   opts = vim.F.if_nil(opts, {})
   if index_rendered and not opts.refresh then
      vim.api.nvim_set_current_buf(M.buf.index)
      return
   end
   if not M.on_display then
      M.on_display = search.filter(db.index, M.state.query)
   end
   local lines = {}
   for i, entry in ipairs(M.on_display) do
      lines[i] = format.entry_name(entry):gsub("\n", "") -- HACK:
   end
   M.show(lines, M.buf.index)
   index_rendered = true
   vim.api.nvim_exec_autocmds("User", {
      pattern = "ShowIndexPost",
      data = { lines = lines },
   })
end

---@class feed.entry_opts
---@field row_idx? integer # will default to cursor row
---@field untag? boolean # default true

---@param opts? feed.entry_opts
function M.show_entry(opts)
   opts = opts or {}
   local untag = vim.F.if_nil(opts.untag, true)
   local row_idx = opts.row_idx or ut.get_cursor_row()
   M.current_index = row_idx
   local entry = M.on_display[row_idx]
   if untag then
      M.untag(row_idx, "unread")
   end
   local raw_str = db:get(entry)
   local lines, urls = urlview(vim.split(raw_str, "\n"))
   M.state.urls = urls
   M.show(lines, M.buf.entry)
   vim.api.nvim_exec_autocmds("User", {
      pattern = "ShowEntryPost",
      data = { lines = lines },
   })
end

function M.get_entry(opts)
   opts = opts or {}
   if opts.db_idx then
      return db[opts.db_idx]
   end
   local row_idx = opts.row_idx or ut.get_cursor_row()
   return M.on_display[row_idx]
end

function M.tag(row_idx, input)
   local id = M.on_display[row_idx].id
   local entry = db:lookup(id)
   if entry then
      entry.tags[input] = true
      db:save()
   end
end

function M.untag(row_idx, input)
   local id = M.on_display[row_idx].id
   local entry = db:lookup(id)
   if entry then
      entry.tags[input] = nil
      db:save()
   end
end

function M.refresh()
   M.on_display = search.filter(db.index, M.state.query or {})
   M.show_index { refresh = true }
end

return M
