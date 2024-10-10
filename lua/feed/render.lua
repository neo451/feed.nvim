local M = {}

---@type table<string, boolean>
M.state = {
   index_rendered = false,
   in_split = false,
}

-- TODO: line by line update
-- TODO: custom file type: FeedIndx, FeedEntry(ts -> markdown/norg)

local entries_on_display, map_to_db_index

local config = require "feed.config"
local db = require "feed.db"(config.db_dir)
local ut = require "feed.utils"
local format = require "feed.format"
local search = require "feed.search"

---@param buf integer
local function set_options(buf)
   for key, value in pairs(config.win_options) do
      vim.api.nvim_set_option_value(key, value, { win = vim.api.nvim_get_current_win() })
   end
   for key, value in pairs(config.buf_options) do
      vim.api.nvim_set_option_value(key, value, { buf = buf })
   end
   vim.cmd.colorscheme(config.colorscheme)
end

---@param cmds table<string, feed.action>
function M.prepare_bufs(cmds)
   M.buf = {
      index = vim.api.nvim_create_buf(false, true),
      entry = vim.api.nvim_create_buf(false, true),
   }
   for rhs, lhs in pairs(config.keymaps.entry) do
      ut.push_keymap(M.buf.entry, lhs, cmds[rhs], rhs)
   end
   for rhs, lhs in pairs(config.keymaps.index) do
      ut.push_keymap(M.buf.index, lhs, cmds[rhs], rhs)
   end
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
   set_options(buf)
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
   lines[1] = M.show_hint()
   for i, entry in ipairs(entries_on_display) do
      lines[i + 1] = format.entry_name(entry)
   end
   M.show(lines, M.buf.index, ut.highlight_index)
   M.state.index_rendered = true
end

local function apply_formatter(buf)
   local ok, conform = pcall(require, "conform")
   if ok then
      vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
      conform.format { bufnr = buf }
      vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
   end
end

---@param db_idx integer
function M.show_entry(db_idx)
   if db_idx == 0 then
      return
   end
   M.current_index = db_idx
   local lines = vim.split(db:at(db_idx), "\n")
   M.show(lines, M.buf.entry, ut.highlight_entry)
   apply_formatter(M.buf.entry)
   db[db_idx].tags.unread = nil
   db:save()
end

---return the entry from the filtered results
---@param buf_idx integer
---@return feed.entry?
function M.get_entry(buf_idx)
   if buf_idx == 0 then
      return
   end
   return entries_on_display[buf_idx] -- TODO:
end

---@return integer
local function cursor_to_db_index()
   local idx = vim.api.nvim_win_get_cursor(0)[1] - 1
   return map_to_db_index[idx]
end

function M.get_entry_under_cursor()
   return M.get_entry(cursor_to_db_index())
end

function M.show_entry_under_cursor()
   local buf_idx = vim.api.nvim_win_get_cursor(0)[1] - 1
   local db_idx = map_to_db_index[buf_idx]
   M.show_entry(db_idx)
end

---@return string
function M.show_hint()
   return "Hint: <M-CR> open in split | <CR> open | + add tag | - remove tag | ? help"
end

function M.refresh()
   db:update_index()
   entries_on_display, map_to_db_index = search.filter(db.index, { must_have = { "unread" } })
   M.show_index(true)
end

return M
