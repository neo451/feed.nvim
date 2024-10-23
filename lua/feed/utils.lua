local M = {}
local URL = require "net.url"
local config = require "feed.config"
local strings = require "plenary.strings"

---@param buf integer
---@param lhs string
---@param rhs string | function
---@param desc? string
function M.push_keymap(buf, lhs, rhs, desc)
   vim.keymap.set("n", lhs, rhs, { noremap = true, silent = true, desc = desc, buffer = buf })
end

local ns = vim.api.nvim_create_namespace "feed"
local normal_grp = vim.api.nvim_get_hl(0, { name = "Normal" })
local light_grp = vim.api.nvim_get_hl(0, { name = "LineNr" })
vim.api.nvim_set_hl(ns, "feed.bold", { bold = true, fg = normal_grp.fg, bg = normal_grp.bg })
vim.api.nvim_set_hl(ns, "feed.light", { bold = false, fg = light_grp.fg, bg = light_grp.bg })
M.ns = ns

---@param buf integer
function M.highlight_entry(buf)
   local len = { 6, 5, 7, 5, 5 }
   for i = 0, 4 do
      vim.highlight.range(buf, ns, "Title", { i, 0 }, { i, len[i + 1] })
   end
end

--- TODO: take displaywidth into account

-- print(#str - strings.strdisplaywidth(str))
---@param buf integer
function M.highlight_index(buf)
   local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
   local len = #lines
   local sections = vim.iter(vim.split(lines[1], " "))
      :filter(function(str)
         return str ~= ""
      end)
      :totable()
   -- Pr(sections)
   -- Pr(vim.split(lines[1]))
   local width = 0
   for i, v in ipairs(config.layout) do
      local str = sections[i]
      local diff
      if str then
         diff = #str - strings.strdisplaywidth(str) -- TODO:
      else
         diff = 0
      end
      for j = 0, len - 1 do
         vim.api.nvim_buf_add_highlight(buf, ns, v.color or "Normal", j, width, v.width + width + diff)
      end
      width = width + v.width
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
   if not url then
      -- print(base_url, url, "!")
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

---@param f fun(cb:function, ...)
function M.cb_to_co(f)
   local f_co = function(...)
      local co = coroutine.running()
      assert(co ~= nil, "The result of cb_to_co must be called within a coroutine.")

      -- f needs to have the callback as its first argument, because varargs
      -- passing doesn’t work otherwise.
      f(function(ret)
         local ok = coroutine.resume(co, ret)
         if not ok then
            error "The coroutine failed"
         end
      end, ...)
      return coroutine.yield()
   end

   return f_co
end

return M
