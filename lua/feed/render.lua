local M = {}

---@type table<string, boolean>
M.state = {
   index_rendered = false,
   in_split = false,
}

local config = require "feed.config"
local db = require("feed.db").db(config.db_dir)
local ut = require "feed.utils"
local format = require "feed.format"

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

function M.show_index()
   if M.state.index_rendered then
      if M.state.in_split then
         vim.cmd "q"
         M.state.in_split = false
      else
         vim.api.nvim_set_current_buf(M.buf.index)
      end
   end
   db:update_index()
   local lines = {}
   lines[1] = M.show_hint()
   for i, entry in ipairs(db.index) do
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

---@param index integer
function M.show_entry(index)
   if index == 0 then
      return
   end
   M.current_index = index
   local lines = vim.split(db:at(index), "\n")
   M.show(lines, M.buf.entry, ut.highlight_entry)
   apply_formatter(M.buf.entry)
   db[index].tags.unread = nil
   db:save()
end

---return the entry from the filtered results
---@param index integer
---@return feed.entry?
function M.get_entry(index)
   if index == 0 then
      return
   end
   return db[index] -- TODO:
end

---@return integer
local function get_cursor_col()
   return vim.api.nvim_win_get_cursor(0)[1] - 1
end

function M.get_entry_under_cursor()
   return M.get_entry(get_cursor_col())
end

function M.show_entry_under_cursor()
   return M.show_entry(get_cursor_col())
end

---@return string
function M.show_hint()
   return "Hint: <M-CR> open in split | <CR> open | + add_tag | - remove | ? help"
end

return M
