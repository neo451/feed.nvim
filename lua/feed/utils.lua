local M = {}
local vim = vim
local api, fn = vim.api, vim.fn
local ipairs, tostring = ipairs, tostring

for k, v in pairs(require("feed.utils.url")) do
   M[k] = v
end

for k, v in pairs(require("feed.utils.treesitter")) do
   M[k] = v
end

---make sure a table is a list insted of a map
---@param t table
---@return table
function M.listify(t)
   return (#t == 0 and not vim.islist(t)) and { t } or t
end

M.load_file = function(fp)
   if type(fp) == "table" then
      fp = tostring(fp)
   end
   local ok, res = pcall(dofile, fp)
   if ok and res then
      return res
   else
      vim.notify(fp .. " not loaded")
      return {}
   end
end

---@param fp string | PathlibPath
---@param object table
M.save_obj = function(fp, object)
   M.save_file(fp, "return " .. vim.inspect(object))
end

---@param path string | PathlibPath
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
   ---@cast path string
   local f = io.open(path, "w")
   if f then
      f:write(content)
      f:close()
      return true
   else
      return false
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
      ret = f:read("*a")
      f:close()
   end
   return ret
end

-- TODO: edge case
-- [观点&amp;评…]
-- [Articles, 新…]
-- [Social Media…]
-- [Articles, 新…]
-- [Articles, 新…]

local strings = require "plenary.strings"

M.align = function(str, width, right_justify)
   local str_len = strings.strdisplaywidth(str)
   str = strings.truncate(str, width)
   return right_justify and string.rep(" ", width - str_len) .. str or str .. string.rep(" ", width - str_len)
end

M.unescape = function(str)
   return str:gsub("(\\%*", "*"):gsub("(\\[%[%]`%-!|#<>_()$.])", function(s)
      return s:sub(2)
   end)
end

function M.get_selection()
   local mode = api.nvim_get_mode().mode

   if mode == "n" then
      return { fn.expand("<cexpr>") }
   end

   local ok, selection = pcall(function()
      return fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = mode })
   end)

   if ok then
      return selection
   end
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
   local alias = {
      ["mini.pick"] = "pick",
      ["mini.notify"] = "mini",
      ["nvim-notify"] = "notify",
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

---split with max length
M.split = function(str, sep, width)
   local ret = {}

   for v in vim.gsplit(str, sep) do
      if vim.fn.strdisplaywidth(v) <= width then
         ret[#ret + 1] = v
      else
         local acc = 0
         local buf = {}
         local len = vim.fn.strdisplaywidth(v)
         for i = 1, len do
            local part = vim.fn.strcharpart(v, i - 1, 1)
            acc = acc + vim.fn.strdisplaywidth(part)
            buf[#buf + 1] = part
            if acc >= width or i == len then
               ret[#ret + 1] = table.concat(buf, "")
               buf = {}
               acc = 0
            end
         end
      end
   end
   return vim.iter(ret)
       :filter(function(v)
          return v ~= ""
       end)
       :totable()
end

function M.capticalize(str)
   return str:sub(1, 1):upper() .. str:sub(2)
end

--- Set window-local options.
---@param win number
---@param wo vim.wo
function M.wo(win, wo)
   for k, v in pairs(wo or {}) do
      vim.api.nvim_set_option_value(k, v, { scope = "local", win = win })
   end
end

--- Set buffer-local options.
---@param buf number
---@param bo vim.bo
function M.bo(buf, bo)
   for k, v in pairs(bo or {}) do
      vim.api.nvim_set_option_value(k, v, { buf = buf })
   end
end

M.list2lookup = function(list)
   local lookup = {}
   for _, v in ipairs(list) do
      lookup[v] = true
   end
   return lookup
end

---@return boolean
M.is_headless = function()
   return vim.tbl_isempty(vim.api.nvim_list_uis())
end



return M
