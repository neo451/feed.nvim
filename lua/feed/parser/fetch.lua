---@diagnostic disable: inject-field
local ut = require "feed.utils"

local M = {}

local function parse_header(data)
   data = data:gsub("\r", "")
   local headers = vim.split(data, "\n")
   local code = table.remove(headers, 1)
   local status = tonumber(string.match(code, "([%w+]%d+)"))
   local res = {}
   for _, line in ipairs(headers) do
      local k, v = string.match(line, "([%w-]+):%s+(.+)")
      k = string.lower(k):gsub("-", "_")
      res[k] = v
   end
   return res, status
end

local function build_header(t)
   if vim.tbl_isempty(t) then
      return {}
   end
   local upper = function(str)
      return string.gsub(" " .. str, "%W%l", string.upper):sub(2)
   end
   local res = {}
   for k, v in pairs(t) do
      res[#res + 1] = "-H"
      res[#res + 1] = upper(k:gsub("_", "%-")) .. ": " .. v
   end
   return res
end

local function fetch(cb, url, opts)
   opts = opts or {}
   local additional = build_header {
      is_none_match = opts.etag,
      if_modified_since = opts.last_modified,
   }
   local cmds = { "curl", "-i", "-L", "-m", opts.timeout or 10, url }
   cmds = vim.list_extend(cmds, additional)
   cmds = vim.list_extend(cmds, opts.cmds or {})
   vim.system(cmds, { text = true }, function(obj)
      -- TODO: handle curl code 28 timeout, 35 unexpected eof
      local split = vim.split(obj.stdout, "\n\n")
      local header = table.remove(split, 1)
      local headers, status = parse_header(header)
      obj.href = headers.location or url
      obj.etag = headers.etag
      obj.last_modified = headers.last_modified
      obj.status = status
      obj.body = obj.stdout:sub(#header + 3, -1)
      obj.headers = headers
      vim.schedule_wrap(cb)(obj)
   end)
end

local fetch_co = ut.cb_to_co(fetch)
--
-- function M.fetch(cb, url, timeout, etag, last_modified, opts)
--    fetch(function(obj)
--       if obj.status == 301 then
--          fetch(cb, obj.location, timeout, etag, last_modified, opts)
--       else
--          vim.schedule_wrap(cb)(obj)
--       end
--    end, url, timeout, etag, last_modified, opts)
-- end

function M.fetch_co(url, opts)
   local obj = fetch_co(url, opts)
   if obj.status == 301 then
      obj = fetch_co(obj.href, opts)
   end
   return obj
end

-- coroutine.wrap(function()
--    local url = "https://neovim.io/news.xml"
--    -- local url = "http://7400.me/atom.xml"
--    -- local url = "http://blog.cnbang.net/feed/"
--    local obj = M.fetch_co(url)
--    print(obj.etag)
--    local obj2 = M.fetch_co(url, { etag = obj.etag, last_modified = obj.last_modified })
--    print(obj2.status, obj2.body ~= nil)
-- end)()
--
return M
