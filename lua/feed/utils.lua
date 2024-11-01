local M = {}
local URL = require "feed.url"
local config = require "feed.config"

---@param buf integer
---@param lhs string
---@param rhs string | function
---@param desc? string
function M.push_keymap(buf, lhs, rhs, desc)
   vim.keymap.set("n", lhs, rhs, { noremap = true, silent = true, desc = desc, buffer = buf })
end

local feed_ns = vim.api.nvim_create_namespace "feed"
local normal_grp = vim.api.nvim_get_hl(0, { name = "Normal" })
local light_grp = vim.api.nvim_get_hl(0, { name = "LineNr" })
vim.api.nvim_set_hl(feed_ns, "feed.bold", { bold = true, fg = normal_grp.fg, bg = normal_grp.bg })
vim.api.nvim_set_hl(feed_ns, "feed.light", { bold = false, fg = light_grp.fg, bg = light_grp.bg })
M.ns = feed_ns -- TODO: ?

---@param buf integer
function M.highlight_entry(buf)
   local len = { 6, 5, 7, 5, 5 }
   for i = 0, 4 do
      vim.highlight.range(buf, feed_ns, "Title", { i, 0 }, { i, len[i + 1] })
   end
end

local utf8 = require "feed.utf8"

local function hl_range(buf, ns, hl_group, row, start, stop)
   local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1]
   -- local res = { 0 }
   -- local acc = 0

   -- for _, str in utf8.codes(line) do
   --    acc = acc + vim.fn.strwidth(str)
   --    res[#res + 1] = acc -- TODO:  break
   -- end

   -- local _start = res[start + 1]
   -- local _stop = res[stop + 2] or #line
   -- if not _start or not _stop then
   --    print(start, stop)
   -- end
   -- print(start, stop)
   local _start = vim.str_byteindex(line, "utf-8", start, false)
   local _stop = vim.str_byteindex(line, "utf-8", stop + 1, false)
   vim.highlight.range(buf, ns, hl_group, { row - 1, _start }, { row - 1, _stop })
end

---TODO:

---@param buf integer
function M.highlight_index(buf)
   local len = #vim.api.nvim_buf_get_lines(buf, 0, -1, false)
   -- print(len)
   local acc = 0
   for _, v in ipairs(config.layout) do
      for i = 1, len do
         hl_range(buf, feed_ns, v.color or "Normal", i, acc, acc + v.width)
      end
      acc = acc + v.width
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
   -- if not url then
   -- print(base_url, url, "!")
   -- end
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
