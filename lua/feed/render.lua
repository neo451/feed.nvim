-- TODO: grey out the entries just read, only hide after refresh

local db = require "feed.db"
local ut = require "feed.utils"
local format = require "feed.format"
local urlview = require "feed.urlview"
local config = require "feed.config"

local M = {
   -- on_display = {},
   query_history = {},
   ---@type table<string, any>
   state = {
      query = config.search.default_query,
      in_split = false,
      in_entry = false,
      in_index = false,
      indexed_once = false,
   },
}

---@param lines string[]
---@param buf integer
local function show(lines, buf)
   vim.bo[buf].modifiable = true
   vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
   vim.api.nvim_set_current_buf(buf)
end

function M.show_index(opts)
   opts = vim.F.if_nil(opts, {})
   if M.state.indexed_once and not opts.refresh then
      vim.api.nvim_set_current_buf(M.buf.index)
      return
   end
   local lines = {}
   for i, id in ipairs(M.on_display) do
      lines[i] = format.entry_name(db[id]):gsub("\n", "") -- HACK: still need to seperate obj and data, too expensive to read text
   end
   show(lines, M.buf.index)
   M.state.indexed_once = true
   M.state.in_index = true
   vim.api.nvim_exec_autocmds("User", {
      pattern = "ShowIndexPost",
      data = { lines = lines },
   })
end

---@class feed.entry_opts
---@field row_idx? integer # will default to cursor row
---@field untag? boolean # default true
---@field id? string # db_id

local function save_entry(id, entry)
   local fp = vim.fs.normalize(config.db_dir) .. "/data/" .. id
   local f = io.open(fp, "w")
   if f then
      f:write("return " .. vim.inspect(entry))
      f:close()
   else
      error("failed to save " .. id .. " " .. vim.inspect(entry))
   end
end

---@param opts? feed.entry_opts
function M.show_entry(opts)
   opts = opts or {}
   local untag = vim.F.if_nil(opts.untag, true)
   local entry, id, row = M.get_entry(opts)
   if row then
      M.current_index = row
   end
   if untag then
      entry.tags.unread = nil
      save_entry(id, entry)
   end
   local raw_str = db[id].content -- TODO:
   local lines, urls = urlview(vim.split(raw_str, "\n"))
   M.state.urls = urls
   show(lines, M.buf.entry)
   vim.api.nvim_exec_autocmds("User", {
      pattern = "ShowEntryPost",
      data = { lines = lines },
   })
end

---@param opts? feed.entry_opts
---@return feed.entry
---@return string
---@return integer?
function M.get_entry(opts)
   opts = opts or {}
   if opts.id then
      return db[opts.id], opts.id, nil
   end
   local row
   if opts.row_idx then
      row = opts.row_idx
   elseif M.state.in_entry or M.state.in_split then
      row = M.current_index
   elseif M.state.in_index then
      row = ut.get_cursor_row()
   end
   local id = M.on_display[row]
   return db[id], id, row
end

function M.refresh()
   M.on_display = db:filter(M.state.query)
   M.show_index { refresh = true }
end

return M
