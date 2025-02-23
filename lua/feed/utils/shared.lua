local M = {}

local vim = vim
local api, fn = vim.api, vim.fn
local ipairs, pcall, dofile, type = ipairs, pcall, dofile, type
local io = io

M.listify = function(t)
   if type(t) ~= "table" then
      return { t }
   end
   return (#t == 0 and not vim.islist(t)) and { t } or t
end

M.load_file = function(fp)
   local ok, res = pcall(dofile, fp)
   if ok and res then
      return res
   else
      vim.notify(fp .. " not loaded")
      return {}
   end
end

---@param fp string
---@param str string
---@param mode "w" | "a"
M.save_file = function(fp, str, mode)
   mode = mode or "w"
   local f = io.open(fp, mode)
   assert(f, fp)
   f:write(str)
   f:close()
end

---@param path string
---@return string?
M.read_file = function(path)
   local ret
   local f = io.open(path, "r")
   assert(f, "could not open " .. path)
   ret = f:read("*a")
   f:close()
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
      api.nvim_set_option_value(k, v, { scope = "local", win = win })
   end
end

--- Set buffer-local options.
---@param buf number
---@param bo vim.bo
function M.bo(buf, bo)
   for k, v in pairs(bo or {}) do
      api.nvim_set_option_value(k, v, { buf = buf })
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
   return vim.tbl_isempty(api.nvim_list_uis())
end

---@param thing table | string
---@param field string | integer
---@return string
M.sensible = function(thing, field, fallback)
   if not thing then
      return fallback
   end
   if type(thing) == "table" then
      --- TODO: handle if list
      if vim.tbl_isempty(thing) then
         return fallback
      elseif type(thing[field]) == "string" then
         return thing[field]
      else
         return fallback
      end
   elseif type(thing) == "string" then
      if thing == "" then
         return fallback
      else
         return thing
      end
   else
      return fallback or ""
   end
end

return M
