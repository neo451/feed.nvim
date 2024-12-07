local M = {}
local vim = vim
local api, fn = vim.api, vim.fn
local ipairs, tostring = ipairs, tostring

for k, v in pairs(require "feed.utils.url") do
   M[k] = v
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
            vim.print("coroutine failed", unpack(args))
            -- error "The coroutine failed"
         end
      end, ...)
      return coroutine.yield()
   end

   return f_co
end

---@param f function
---@return function
function M.wrap(f)
   return function(...)
      coroutine.wrap(f)(...)
   end
end

M.pdofile = function(fp)
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
M.save_file = function(path, content)
   if not path then
      return
   end
   content = content or ""
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
M.read_file = function(path)
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

---@param str string
---@param len integer
---@return string
local truncate = function(str, len)
   if fn.strdisplaywidth(str) <= len then
      return str
   end
   local dots = "…"
   local start = 0
   local current = 0
   local result = ""
   local len_of_dots = fn.strdisplaywidth(dots)
   local concat = function(a, b, dir)
      if dir > 0 then
         return a .. b
      else
         return b .. a
      end
   end
   while true do
      local part = fn.strcharpart(str, start, 1)
      current = current + fn.strdisplaywidth(part)
      if (current + len_of_dots) > len then
         result = concat(result, dots, 1)
         break
      end
      result = concat(result, part, 1)
      start = start + 1
   end
   return result
end

M.align = function(str, width, right_justify)
   local str_len = fn.strdisplaywidth(str)
   str = truncate(str, width)
   return right_justify and string.rep(" ", width - str_len) .. str or str .. string.rep(" ", width - str_len)
end

M.input = M.cb_to_co(function(cb, opts)
   pcall(vim.ui.input, opts, vim.schedule_wrap(cb))
end)

M.select = M.cb_to_co(function(cb, items, opts)
   pcall(vim.ui.select, items, opts, cb)
end)

M.unescape = function(str)
   return string.gsub(str, "(\\[%[%]`*!|#<>_()])", function(s)
      return s:sub(2)
   end)
end

function M.get_selection()
   local mode = api.nvim_get_mode().mode

   if mode == "n" then
      return { fn.expand "<cexpr>" }
   end

   local ok, selection = pcall(function()
      return fn.getregion(vim.fn.getpos "v", vim.fn.getpos ".", { type = mode })
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
   local last_nonblank = fn.prevnonblank(n_lines)
   local buf = api.nvim_get_current_buf()
   api.nvim_set_option_value("modifiable", true, { buf = buf })
   if last_nonblank < n_lines then
      api.nvim_buf_set_lines(0, last_nonblank, n_lines - 1, true, {})
   end
   api.nvim_set_option_value("modifiable", false, { buf = buf })
end

---@param choices table | string
---@return string?
M.choose_backend = function(choices)
   local alias = {
      ["mini.pick"] = "pick",
      ["mini.notify"] = "notify",
   }
   if type(choices) == "string" then
      return alias[choices] or choices
   end
   for _, v in ipairs(choices) do
      if pcall(require, v) then
         return alias[v] and alias[v] or v
      end
   end
end

---@param feeds feed.opml
---@return string[]
M.feedlist = function(feeds)
   return vim.iter(feeds)
      :filter(function(_, v)
         return type(v) == "table"
      end)
      :fold({}, function(acc, k)
         table.insert(acc, k)
         return acc
      end)
end

return M
