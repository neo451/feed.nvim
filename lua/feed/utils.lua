local M = {}
local URL = require "feed.lib.url"
local strings = require "plenary.strings"

local feed_ns = vim.api.nvim_create_namespace "feed"
local normal_grp = vim.api.nvim_get_hl(0, { name = "Normal" })
local light_grp = vim.api.nvim_get_hl(0, { name = "LineNr" })
vim.api.nvim_set_hl(feed_ns, "feed.bold", { bold = true, fg = normal_grp.fg, bg = normal_grp.bg })
vim.api.nvim_set_hl(feed_ns, "feed.light", { bold = false, fg = light_grp.fg, bg = light_grp.bg })

---@param buf integer
function M.highlight_entry(buf)
   local len = { 6, 5, 7, 5, 5 }
   for i = 0, 4 do
      vim.highlight.range(buf, feed_ns, "Title", { i, 0 }, { i, len[i + 1] })
   end
end

---@param base_url string
---@param url string
---@return string?
function M.url_resolve(base_url, url)
   if not base_url then
      return url
   end
   if not url then
      return base_url
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
   return tostring(M.url_resolve(base_uri, xml_base))
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
            print "coroutine failed"
            -- error "The coroutine failed"
         end
      end, ...)
      return coroutine.yield()
   end

   return f_co
end

function M.run(co)
   coroutine.resume(coroutine.create(co))
end

---@param f function
---@return function
function M.wrap(f)
   return function(...)
      coroutine.wrap(f)(...)
   end
end

function M.pdofile(fp)
   if type(fp) == "table" then
      fp = tostring(fp)
   end
   local ok, res = pcall(dofile, fp)
   if ok and res then
      return res
   else
      print("failed to load db file ", fp, res)
   end
end

---@param path string
---@param content string
function M.save_file(path, content)
   if type(path) == "table" then
      ---@diagnostic disable-next-line: param-type-mismatch
      path = tostring(path)
   end
   local f = io.open(path, "w")
   if f then
      f:write(content)
      f:close()
   end
end

---@param path string
---@return string?
function M.read_file(path)
   local ret

   if type(path) == "table" then
      ---@diagnostic disable-next-line: param-type-mismatch
      path = tostring(path)
   end
   local f = io.open(path, "r")
   if f then
      ret = f:read "*a"
      f:close()
   end
   return ret
end

---porperly align, justify and trucate the title
---@param str string
---@param max_len integer
---@param right_justify boolean
---@return string
function M.align(str, max_len, right_justify)
   str = str or ""
   right_justify = right_justify or false
   local len = strings.strdisplaywidth(str)
   if len < max_len then
      return strings.align_str(str, max_len, right_justify)
   else
      return strings.align_str(strings.truncate(str, max_len), max_len, right_justify)
   end
end

function M.append(str)
   vim.wo.winbar = vim.wo.winbar .. str
end

function M.comp(name, str, width, grp)
   width = width or #str
   vim.g["feed_" .. name] = str
   M.append("%#" .. grp .. "#")
   M.append("%-" .. width + 1 .. "." .. width + 1 .. "{g:feed_" .. name .. "}")
end

function M.looks_like_url(str)
   local allow = { https = true, http = true }
   return allow[URL.parse(str).scheme] ~= nil
end

function M.require(mod)
   return setmetatable({}, {
      __index = function(t, key)
         if vim.tbl_isempty(t) then
            t = require(mod)
         end
         return t[key]
      end,
   })
end

M.input = M.cb_to_co(function(cb, opts)
   pcall(vim.ui.input, opts, vim.schedule_wrap(cb))
end)

M.select = M.cb_to_co(function(cb, items, opts)
   pcall(vim.ui.select, items, opts, cb)
end)

M.unescape = function(str)
   return string.gsub(str, "(\\[%[%]`*!|#<>])", function(s)
      return s:sub(2)
   end)
end

return M
