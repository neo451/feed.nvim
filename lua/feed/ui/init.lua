local ut = require "feed.utils"
local db = ut.require "feed.db"
local format = require "feed.ui.format"
local urlview = require "feed.ui.urlview"
local config = require "feed.config"
local NuiText = require "nui.text"
local health = require "feed.health"
local entities = require "feed.lib.entities"
local decode = entities.decode

-- TODO: grey out the entries just read, only hide after refresh
local function html_to_md(id)
   if not health.check_binary_installed { name = "pandoc", min_ver = 3 } then
      return "you need pandoc to view feeds https://pandoc.org"
   end
   local sourced_file = require("plenary.debug_utils").sourced_filepath()
   local filter = vim.fn.fnamemodify(sourced_file, ":h") .. "/pandoc_filter.lua"
   local md = vim.system({
      "pandoc",
      "-f",
      "html",
      "-t",
      filter,
      "--wrap=none",
      db.dir .. "/data/" .. id,
   }, { text = true })
      :wait().stdout
   return ut.unescape(md)
end

local og_colorscheme, og_winbar

og_colorscheme = vim.g.colors_name

local M = {
   on_display = nil,
   index = nil,
   state = {
      query = config.search.default_query,
      in_split = false,
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

---@param buf integer
---@param text string
---@param hi_grp string
---@param col integer
---@param row integer
local function render_text(buf, text, hi_grp, col, row)
   local obj = NuiText(text, hi_grp)
   obj:render_char(buf, -1, row, col)
end

---@param buf integer
---@param entry feed.entry
---@param row integer
local function show_line(buf, entry, row)
   vim.api.nvim_buf_set_lines(buf, row - 1, row, false, { "" })
   local formats = format.gen_format(entry, main_comp)
   for _, v in ipairs(formats) do
      render_text(buf, decode(v.text) or v.text, v.color, v.width, row)
   end
end

M.show_line = show_line

function M.show_index(opts)
   opts = vim.F.if_nil(opts, {})
   local buf = M.index or vim.api.nvim_create_buf(false, true)
   M.index = buf
   vim.api.nvim_buf_set_name(buf, "FeedIndex")
   local len = #vim.api.nvim_buf_get_lines(buf, 0, -1, false)
   vim.bo[buf].modifiable = true
   for i = 1, len do
      vim.api.nvim_buf_set_lines(buf, i, i + 1, false, { "" })
   end
   if not M.on_display then
      M.on_display = db:filter(M.state.query)
   end
   vim.bo[buf].modifiable = true
   for i, id in ipairs(M.on_display) do
      show_line(buf, db[id], i)
   end
   vim.api.nvim_set_current_buf(buf)
   M.show_winbar()
   vim.api.nvim_exec_autocmds("User", { pattern = "ShowIndexPost" })
end

local function kv(k, v)
   return string.format("%s: %s", k, v)
end

---@class feed.entry_opts
---@field row_idx? integer # will default to cursor row
---@field untag? boolean # default true
---@field id? string # db_id
---@field buf? integer # db_id

---@param opts? feed.entry_opts
function M.show_entry(opts)
   opts = opts or {}
   ---@type integer
   local buf = opts.buf or vim.api.nvim_create_buf(false, true)
   if not pcall(vim.api.nvim_buf_get_name, buf) then
      pcall(vim.api.nvim_buf_set_name, buf, "FeedEntry")
   end
   local untag = vim.F.if_nil(opts.untag, true)
   local show = vim.F.if_nil(opts.show, true)
   local entry, id, row = M.get_entry(opts)
   if not entry or not id then
      return
   end
   if row then
      M.current_index = row
   end
   if untag then
      db:tag(id, "read")
   end
   local lines = {}

   -- TODO: use render_text
   lines[#lines + 1] = entry.title and kv("Title", format.title(entry))
   lines[#lines + 1] = entry.time and kv("Date", format.date(entry))
   lines[#lines + 1] = entry.author and kv("Author", entry.author)
   lines[#lines + 1] = entry.feed and kv("Feed", entry.feed)
   lines[#lines + 1] = entry.link and kv("Link", entry.link)
   lines[#lines + 1] = ""

   local entry_lines
   local md = html_to_md(id)
   entry_lines, M.state.urls = urlview(vim.split(md, "\n"), entry.link)
   vim.list_extend(lines, entry_lines)

   vim.bo[buf].modifiable = true
   vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
   if show then
      vim.api.nvim_set_current_buf(buf)
      vim.wo.winbar = ""
   end
   vim.api.nvim_exec_autocmds("User", { pattern = "ShowEntryPost" })
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
   local _, bufname = pcall(vim.api.nvim_buf_get_name, vim.api.nvim_get_current_buf())
   opts = opts or {}
   if opts.id then
      return db[opts.id], opts.id, nil
   end
   local row
   if opts.row_idx then
      row = opts.row_idx
   elseif bufname:find "FeedEntry" then
      row = M.current_index
   elseif bufname:find "FeedIndex" then
      row = ut.get_cursor_row()
   else
      return
   end
   local id = M.on_display[row]
   return db[id], id, row
end

function M.refresh(opts)
   -- TODO: remove trailing empty lines
   opts = opts or {}
   if opts.query then
      M.state.query = opts.query
   end
   M.on_display = db:filter(M.state.query)
   M.show_index {}
   ut.trim_last_lines()
end

local function restore_state()
   vim.cmd "set cmdheight=1"
   vim.wo.winbar = "" -- TODO: restore the user's old winbar is there is
   pcall(vim.cmd.colorscheme, og_colorscheme)
end

function M.quit()
   if ut.in_index() then
      vim.cmd "bd!"
      vim.api.nvim_exec_autocmds("User", { pattern = "QuitIndexPost" })
      restore_state()
   else
      vim.cmd "bd!"
      M.show_index()
      vim.api.nvim_exec_autocmds("User", { pattern = "QuitEntryPost" })
   end
end

return M
