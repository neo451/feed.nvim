local M = {}

---@type table<string, any>
M.state = {
   index_rendered = false,
   in_split = false,
}

-- TODO: line by line update
-- TODO: custom file type: FeedIndx, FeedEntry(ts -> markdown/norg)

local entries_on_display, map_to_db_index

local config = require "feed.config"
local db = require "feed.db"
local ut = require "feed.utils"
local format = require "feed.format"
local search = require "feed.search"
local urlview = require "feed.urlview"

--- TODO: index and buffer should have their own window

function M.prepare_bufs()
   if M.buf then
      return
   end
   M.buf = {
      index = vim.api.nvim_create_buf(false, true),
      entry = vim.api.nvim_create_buf(false, true),
   }
   vim.api.nvim_buf_set_name(M.buf.index, "FeedIndex")
   vim.api.nvim_buf_set_name(M.buf.entry, "FeedEntry")
end

---@param lines string[]
---@param buf integer
---@param callback fun(buf: integer)
function M.show(lines, buf, callback)
   vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
   vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
   vim.api.nvim_set_current_buf(buf)
   if callback then
      callback(buf)
   end
end

---@param refresh boolean?
function M.show_index(refresh)
   if M.state.index_rendered and not refresh then
      vim.api.nvim_set_current_buf(M.buf.index)
      return
   end
   db:update_index()
   if not entries_on_display then
      entries_on_display, map_to_db_index = search.filter(db.index, { must_have = { "unread" } })
   end
   local lines = {}
   for i, entry in ipairs(entries_on_display) do
      lines[i] = format.entry_name(entry)
   end
   M.show(lines, M.buf.index, ut.highlight_index)
   M.state.index_rendered = true
end

---@class feed.entry_opts
---@field db_idx? integer
---@field row_idx? integer # will default to cursor row

---@param opts? feed.entry_opts
function M.show_entry(opts)
   local _, db_idx, row_idx = M.get_entry(opts)
   M.current_index = row_idx
   local raw_str = db:at(db_idx)
   local lines, urls = urlview(vim.split(raw_str, "\n"))
   M.state.urls = urls
   M.show(lines, M.buf.entry, ut.highlight_entry)
   db[db_idx].tags.unread = nil
   db:save()
end

function M.get_entry(opts)
   opts = opts or {}
   local row_idx = opts.row_idx or vim.api.nvim_win_get_cursor(0)[1]
   local db_idx = opts.db_idx or map_to_db_index[row_idx]
   return db[db_idx], db_idx, row_idx
end

---@return integer
function M.cursor_to_db_index()
   local idx = vim.api.nvim_win_get_cursor(0)[1]
   return map_to_db_index[idx]
end

---@return integer
function M.buf_to_db_index(buf_idx)
   return map_to_db_index[buf_idx]
end

function M.get_entry_under_cursor()
   return M.get_entry(M.cursor_to_db_index())
end

function M.tag(buf_idx, input)
   local idx = map_to_db_index[buf_idx]
   db[idx].tags[input] = true
   db:save() -- TODO: do it on exit / or only if ":w" , make an option
end

function M.untag(buf_idx, input)
   local idx = map_to_db_index[buf_idx]
   db[idx].tags[input] = nil
   db:save() -- TODO: do it on exit / or only if ":w" , make an option
end

---TODO: option to show more useful hints like last updated, unread/read
---@return string
function M.show_hint()
   vim.wo[0].winbar = config.layout.header
end

function M.refresh()
   db:update_index()
   entries_on_display, map_to_db_index = search.filter(db.index, { must_have = { "unread" } })
   M.show_index(true)
end

return M
