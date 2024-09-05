local M = {
   state = {
      rendered_once = nil, -- to keep track of when to render_index when using show_index command
   },
   index = nil,
}

local flatdb = require "feed.db"
local config = require "feed.config"
local ut = require "feed.utils"
local db = flatdb.db(config.db_dir)
local date = require "feed.date"

---@class feed.render
---@field state table<string, boolean>
---@field curent_index integer
---@field current_entry fun(): table<string, any>
---@field show_entry fun(row: integer)

---@return feed.entry
function M.current_entry()
   local row = vim.api.nvim_win_get_cursor(0)[1]
   return db.index[row - 1]
end

---@param index integer
---@return feed.entry
function M.get_entry(index)
   return db.index[index]
end

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

local function kv(k, v)
   return string.format("%s: %s", k, v)
end

---@param entry feed.entry
---@return table
function M.format_entry(entry)
   local lines = {}
   lines[1] = kv("Title", entry.title)
   lines[2] = kv("Date", date.new_from_int(entry.time))
   lines[3] = kv("Author", entry.author or entry.feed)
   lines[4] = kv("Feed", entry.feed)
   lines[5] = kv("Link", entry.link)
   lines[6] = ""
   lines[7] = db:get(entry)
   return lines
end

--- TODO: move to entry.lua
---@param entry feed.entry
---@return string
function M.entry_name(entry)
   local format = "%s %s %s %s"
   -- vim.api.nvim_win_get_width(0) -- TODO: use this or related autocmd to truncate title
   return string.format(
      format,
      tostring(date.new_from_int(entry.time)), -- TODO: use width
      ut.format_title(entry.title, config.layout.title.width, config.layout.title.right_justify),
      entry.feed,
      ut.format_tags(entry.tags)
   )
end

---@param cmds feed.action[]
function M.prepare_bufs(cmds)
   M.buf = {
      index = vim.api.nvim_create_buf(false, true),
      entry = {},
   }
   for i = 1, 3 do
      M.buf.entry[i] = vim.api.nvim_create_buf(false, true)
      for rhs, lhs in pairs(config.keymaps.entry) do
         ut.push_keymap(M.buf.entry[i], lhs, cmds[rhs])
      end
   end
   for rhs, lhs in pairs(config.keymaps.index) do
      ut.push_keymap(M.buf.index, lhs, cmds[rhs])
   end
end

---render whole db as flat list
function M.show_index()
   db:update_index()
   local lines = {}
   lines[1] = M.show_hint()
   for i, entry in ipairs(db.index) do
      lines[i + 1] = M.entry_name(entry)
   end
   M.show(lines, M.buf.index, ut.highlight_index)
   M.state.rendered_once = true
end

---@param index integer
function M.show_entry(index)
   local entry = M.get_entry(index)
   M.show(M.format_entry(entry), M.buf.entry[2], ut.highlight_entry)
   entry.tags.unread = nil
   db:save()
end

---@return string
function M.show_hint()
   return "Hint: <M-CR> open in split | <CR> open | + add_tag | - remove | ? help"
end

return M
