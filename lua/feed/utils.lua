local M = {}
local URL = require "feed.url"
local config = require "feed.config"
local hl = vim.hl or vim.highlight

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
            print "coroutine failed"
            -- error "The coroutine failed"
         end
      end, ...)
      return coroutine.yield()
   end

   return f_co
end

function M.pdofile(fp)
   local ok, res = pcall(dofile, fp)
   if ok and res then
      return res
   else
      print("failed to load db file ", fp, res)
   end
end

---@param path string
---@param content string
---@return boolean
function M.save_file(path, content)
   local f = io.open(path, "w")
   if f then
      f:write(content)
      f:close()
      return true
   else
      return false
   end
end

--@param path string
---@return string?
function M.read_file(path)
   local ret
   local f = io.open(path, "r")
   if f then
      ret = f:read "*a"
      f:close()
   else
      return
   end
   return ret
end

local strings = require "plenary.strings"

---porperly align, justify and trucate the title
---@param str string
---@param max_len integer
---@param right_justify boolean
---@return string
function M.align(str, max_len, right_justify)
   right_justify = right_justify or false
   local len = strings.strdisplaywidth(str)
   if len < max_len then
      return strings.align_str(str, max_len, right_justify)
   else
      return strings.align_str(strings.truncate(str, max_len), max_len, right_justify)
   end
end

function M.comma_sp(str)
   return vim.iter(vim.gsplit(str, ",")):fold({}, function(acc, v)
      v = v:gsub("%s", "")
      if v ~= "" then
         acc[v] = true
      end
      return acc
   end)
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

return M
