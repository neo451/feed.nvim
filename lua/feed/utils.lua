local M = {}
local URL = require "feed.lib.url"
local api = vim.api

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
   return api.nvim_win_get_cursor(0)[1]
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
      local args = { ... }

      -- f needs to have the callback as its first argument, because varargs
      -- passing doesn’t work otherwise.
      f(function(ret)
         local ok = coroutine.resume(co, ret)
         if not ok then
            print("coroutine failed", unpack(args))
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
   local strings = require "plenary.strings"
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
   return string.gsub(str, "(\\[%[%]`*!|#<>_])", function(s)
      return s:sub(2)
   end)
end

function M.get_selection()
   local mode = api.nvim_get_mode().mode

   if mode == "n" then
      return { vim.fn.expand "<cexpr>" }
   end

   local ok, selection = pcall(function()
      return vim.fn.getregion(vim.fn.getpos "v", vim.fn.getpos ".", { type = mode })
   end)

   if ok then
      return selection
   end
end

function M.in_index()
   return api.nvim_buf_get_name(0):find "FeedIndex" ~= nil
end

function M.in_entry()
   return api.nvim_buf_get_name(0):find "FeedEntry" ~= nil
end

--- Trim last blank lines
M.trim_last_lines = function()
   local n_lines = api.nvim_buf_line_count(0)
   local last_nonblank = vim.fn.prevnonblank(n_lines)
   local buf = api.nvim_get_current_buf()
   api.nvim_set_option_value("modifiable", true, { buf = buf })
   if last_nonblank < n_lines then
      api.nvim_buf_set_lines(0, last_nonblank, n_lines - 1, true, {})
   end
   api.nvim_set_option_value("modifiable", false, { buf = buf })
end

M.choose_search_backend = function()
   for _, v in ipairs(require("feed.config").search.backends) do
      if pcall(require, v) then
         if v == "mini.pick" then
            return "pick"
         end
         return v
      end
   end
end

return M
