local M = {}

local api = vim.api
local ipairs, pcall, dofile, type = ipairs, pcall, dofile, type
local io = io
local log = require("feed.lib.log")

---@generic T
---@param t T | T[]
---@return T[]
M.listify = function(t)
   if type(t) ~= "table" then
      return { t }
   end
   if #t == 0 and not vim.islist(t) then
      return { t }
   end
   ---@cast t T[]
   return t
end

---@generic T
---@param list T[]
---@return table<T, boolean>
M.list2lookup = function(list)
   local lookup = {}
   for _, v in ipairs(list) do
      lookup[v] = true
   end
   return lookup
end

---@generic T
---@param t (T | T[] | nil)[]
---@return T[]
M.tbl_flatten = function(t)
   return vim.iter(t):flatten():totable()
end

---@param fp string
---@return any?
M.load_file = function(fp)
   local ok, res = pcall(dofile, fp)
   if ok and res then
      return res
   else
      if vim.g.feed_debug then
         ---@diagnostic disable-next-line: undefined-field
         log.info(fp .. " not loaded")
         vim.notify(fp .. " not loaded")
      end
      return nil
   end
end

---@param fp string
---@param str string
---@param mode? "w" | "a"
---@return boolean
M.save_file = function(fp, str, mode)
   mode = mode or "w"
   local f = io.open(fp, mode)
   if f then
      f:write(str)
      f:close()
      return true
   else
      return false
   end
end

---@param path string
---@return string
M.read_file = function(path)
   local f = assert(io.open(path, "r"), "could not open " .. path)
   local ret = assert(f:read("*a"), "could not read " .. path)
   f:close()
   return ret
end

---@return boolean
M.in_index = function()
   return api.nvim_buf_get_name(0):find("FeedIndex") ~= nil
end

---@return boolean
M.in_entry = function()
   return api.nvim_buf_get_name(0):find("FeedEntry") ~= nil
end

---@param choices table | string
---@return string?
M.choose_backend = function(choices)
   if type(choices) == "string" then
      return choices
   end
   for _, v in ipairs(choices) do
      if pcall(require, v) then
         return v
      end
   end
end

---@param feeds feed.opml
---@param all boolean
---@return string[]
M.feedlist = function(feeds, all)
   return vim.iter(feeds)
      :filter(function(_, v)
         if all then
            return true
         else
            return type(v) == "table"
         end
      end)
      :fold({}, function(acc, k)
         table.insert(acc, k)
         return acc
      end)
end

---@param url string
---@param feeds feed.opml
---@return string
M.url2name = function(url, feeds)
   if feeds[url] then
      local feed = feeds[url]
      if feed.title then
         return feed.title or url
      end
   end
   return url
end

--- Set window-local options.
---@param win integer
---@param wo? table<string, any>
M.wo = function(win, wo)
   ---@type vim.api.keyset.option
   local opts = { scope = "local", win = win }
   for k, v in pairs(wo or {}) do
      ---@cast k string
      api.nvim_set_option_value(k, v, opts)
   end
end

--- Set buffer-local options.
---@param buf integer
---@param bo? table<string, any>
M.bo = function(buf, bo)
   ---@type vim.api.keyset.option
   local opts = { buf = buf }
   for k, v in pairs(bo or {}) do
      ---@cast k string
      api.nvim_set_option_value(k, v, opts)
   end
end

---1. replace html entities,
---2. replace newline as space,
---3. trims
---@param str string?
---@return string?
M.feed_field_cleanup = function(str)
   str = str and require("feed.lib.entities").decode(str)
   str = str and string.gsub(str, "\n", " ")
   str = str and vim.trim(str)
   return str
end

return M
