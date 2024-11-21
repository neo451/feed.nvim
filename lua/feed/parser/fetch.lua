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
      k = k and string.lower(k):gsub("-", "_")
      if k then
         res[k] = v
      end
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
   local cmds = { "curl", "-i", "--connect-timeout", opts.timeout or 10, url }
   cmds = vim.list_extend(cmds, additional)
   cmds = vim.list_extend(cmds, opts.cmds or {})
   vim.system(cmds, { text = true }, function(obj)
      -- TODO: handle curl code 28 timeout, 35 unexpected eof
      -- TODO: curl: (52) Empty reply from server
      if obj.code == 0 then
         local split = vim.split(obj.stdout, "\n\n")
         local header = table.remove(split, 1)
         local headers, status = parse_header(header)
         obj.href = headers.location or url
         obj.etag = headers.etag
         obj.last_modified = headers.last_modified
         obj.status = status
         obj.body = obj.stdout:sub(#header + 3, -1)
         -- print(obj.body)
         obj.headers = headers
         vim.schedule_wrap(cb)(obj)
      end
      -- print(obj.code)
   end)
end

local fetch_co = ut.cb_to_co(fetch)

local redirect = {
   [301] = true,
   [302] = true,
   [307] = true,
   [308] = true,
}

function M.fetch_co(url, opts)
   local obj = fetch_co(url, opts)
   if redirect[obj.status] then
      local new_loc = ut.url_resolve(url, obj.href)
      return M.fetch_co(new_loc, opts)
   end
   return obj
end
--
-- local run = require("feed.utils").run
--
-- run(function()
--    print(M.fetch_co("http://rss.badassjs.com/", {}))
-- end)

return M
