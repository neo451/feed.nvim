local M = {}

---@type table<string, any>
M.state = {
   in_split = false,
   in_entry = false,
   on_display = {},
   query_history = {},
}

-- TODO: grey out the entries just read, only hide after refresh

local db = require "feed.db"
local ut = require "feed.utils"
local format = require "feed.format"
local search = require "feed.search"
local urlview = require "feed.urlview"

---@param lines string[]
---@param buf integer
function M.show(lines, buf)
   vim.bo[buf].modifiable = true
   vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
   vim.api.nvim_set_current_buf(buf)
end

function M.show_index(opts)
   opts = vim.F.if_nil(opts, {})
   if M.index_rendered and not opts.refresh then
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
   M.index_rendered = true
   vim.api.nvim_exec_autocmds("User", {
      pattern = "ShowIndexPost",
      data = { lines = lines },
   })
end

---@class feed.entry_opts
---@field row_idx? integer # will default to cursor row
---@field untag? boolean # default true
---@field id? string # db_id

---@param opts? feed.entry_opts
function M.show_entry(opts)
   opts = opts or {}
   local untag = vim.F.if_nil(opts.untag, true)
   local entry, id = M.get_entry(opts)
   if untag then
      db[id].tags.unread = nil
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

---@param opts? feed.entry_opts
---@return feed.entry
---@return string
function M.get_entry(opts)
   opts = opts or {}
   if opts.id then
      return db[opts.id], opts.id
   end
   local row_idx = M.state.in_entry and M.current_index or ut.get_cursor_row()
   local entry = M.on_display[row_idx]
   return entry, entry.id
end

function M.refresh()
   M.on_display = search.filter(db.index, M.state.query or {})
   M.show_index { refresh = true }
end

return M
