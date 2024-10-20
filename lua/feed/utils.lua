local M = {}
local URL = require "net.url"

---@param buf integer
---@param lhs string
---@param rhs string | function
---@param desc? string
function M.push_keymap(buf, lhs, rhs, desc)
   vim.keymap.set("n", lhs, rhs, { noremap = true, silent = true, desc = desc, buffer = buf })
end

local ns = vim.api.nvim_create_namespace "feed"
local normal_grp = vim.api.nvim_get_hl(0, { name = "Normal" })
local light_grp = vim.api.nvim_get_hl(0, { name = "Whitespace" })
vim.api.nvim_set_hl(ns, "feed.bold", { bold = true, fg = normal_grp.fg, bg = normal_grp.bg })
vim.api.nvim_set_hl(ns, "feed.light", { bold = true, fg = light_grp.fg, bg = light_grp.bg })
M.ns = ns

---@param buf integer
function M.highlight_entry(buf)
   local len = { 6, 5, 7, 5, 5 }
   for i = 0, 4 do
      vim.highlight.range(buf, ns, "Title", { i, 0 }, { i, len[i + 1] })
   end
end

---@param buf integer
function M.highlight_index(buf)
   local len = #vim.api.nvim_buf_get_lines(buf, 0, -1, true) -- TODO: api??
   for i = 0, len do
      vim.api.nvim_buf_add_highlight(buf, ns, "Title", i, 0, 10)
      vim.api.nvim_buf_add_highlight(buf, ns, "feed.bold", i, 0, -1)
   end
end

function M.clamp(min, value, max)
   return math.min(max, math.max(min, value))
end

function M.cycle(i, n)
   return i % n == 0 and n or i % n
end

---@param base_url string | table
---@param url string | table
---@return string
function M.url_resolve(base_url, url)
   if not base_url then
      if url then
         return tostring(url)
      end
   end
   return tostring(URL.resolve(base_url, url))
end

---@param el table
---@param base_uri string
---@return string
function M.url_rebase(el, base_uri)
   local xml_base = el["xml:base"]
   if not xml_base then
      return base_uri
   end
   return tostring(M.url_resolve(xml_base, base_uri))
end

---make sure a table is a list insted of a map
function M.listify(t)
   return (#t == 0 and not vim.islist(t)) and { t } or t
end

---@return integer
function M.get_cursor_row()
   return vim.api.nvim_win_get_cursor(0)[1]
end

--- Telescope Wrapper around vim.notify
---@param funname string: name of the function that will be
---@param opts table: opts.level string, opts.msg string, opts.once bool
function M.notify(funname, opts)
   opts.once = vim.F.if_nil(opts.once, false)
   local level = vim.log.levels[opts.level]
   if not level then
      error("Invalid error level", 2)
   end
   local notify_fn = opts.once and vim.notify_once or vim.notify
   notify_fn(string.format("[feed.%s]: %s", funname, opts.msg), level, {
      title = "feed.nvim",
   })
end

return M
