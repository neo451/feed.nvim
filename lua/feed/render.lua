local M = {}

---@type table<string, any>
M.state = {
   index_rendered = false,
   in_split = false,
   on_display = {},
   query_history = {},
}

-- TODO: line by line update
-- TODO: custom file type: FeedIndx, FeedEntry(ts -> markdown/norg)

local db = require "feed.db"
local ut = require "feed.utils"
local format = require "feed.format"
local search = require "feed.search"
local urlview = require "feed.urlview"

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
function M.show(lines, buf, opts)
   opts = opts or { show = true }
   vim.bo[buf].modifiable = true
   vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
   if opts.show then
      vim.api.nvim_set_current_buf(buf)
   end
   if opts.callback then
      opts.callback(buf)
   end
end

function M.show_index(opts)
   opts = vim.F.if_nil(opts, {})
   if M.state.index_rendered and not opts.refresh then
      vim.api.nvim_set_current_buf(M.buf.index)
      return
   end
   if not M.on_display then
      db:update_index()
      M.on_display = search.filter(db.index, M.state.query)
   end
   local lines = {}
   for i, entry in ipairs(M.on_display) do
      lines[i] = format.entry_name(entry):gsub("\n", "") -- HACK:
   end
   M.show(lines, M.buf.index, { callback = ut.highlight_index, show = opts.show or true })
   M.state.index_rendered = true
end

---@class feed.entry_opts
---@field db_idx? integer
---@field row_idx? integer # will default to cursor row
---@field show? boolean
---@field untag? boolean

---@param opts? feed.entry_opts
function M.show_entry(opts)
   opts = opts or {}
   local untag = vim.F.if_nil(opts.untag, true)
   local entry
   -- if opts.db_idx then
   --    entry = db[opts.db_idx]
   --    M.current_index = opts.db_idx
   -- else
   local row_idx = opts.row_idx or ut.get_cursor_row()
   M.current_index = row_idx
   entry = M.on_display[row_idx]
   if untag then
      M.untag(row_idx, "unread")
   end
   -- end
   local raw_str = db:get(entry)
   local lines, urls = urlview(vim.split(raw_str, "\n"))
   M.state.urls = urls
   M.show(lines, M.buf.entry, { callback = ut.highlight_entry, show = vim.F.if_nil(opts.show, true) })
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
