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

for k, v in pairs(require("feed.utils.strings")) do
   M[k] = v
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

M.listify = function(t)
   return (#t == 0 and not vim.islist(t)) and { t } or t
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

M.get_selection = function()
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
