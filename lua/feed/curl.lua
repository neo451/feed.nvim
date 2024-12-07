---@diagnostic disable: inject-field
local ut = require "feed.utils"
local log = require "feed.lib.log"
local config = require "feed.config"

local M = {}
local read_file = ut.read_file

local function parse(data)
   local headers = vim.split(data, "\r\n")
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
   res.status = status
   return res
end

local function parse_header(fp, url)
   local data = read_file(fp)
   vim.uv.fs_unlink(fp)
   if data then
      local sects = vim.split(data, "\r\n\r\n")
      local headers = {}
      for _, sect in ipairs(sects) do
         headers = vim.tbl_extend("keep", headers, parse(sect))
      end
      return headers
   else
      log.warn(url, "has invalid header")
   end
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

local function spawn(cmds, url, dump_fp, cb)
   vim.system(cmds, { text = true, detach = true }, function(obj)
      if obj.code == 0 then
         local headers = parse_header(dump_fp, url)
         obj.href = headers.location or url
         obj.etag = headers.etag
         obj.last_modified = headers.last_modified
         obj.status = headers.status
         obj.body = obj.stdout
         obj.headers = headers
         if obj.body:find "<!DOCTYPE html>" then
            cb { status = 404 }
            return
         end
         vim.schedule_wrap(cb)(obj)
      else
         log.warn("[feed.nvim]:", url, obj.stderr)
      end
   end)
end

local function fetch(cb, url, opts)
   assert(type(url) == "string", "url must be a string")
   assert(type(cb) == "function", "callback is required")
   opts = opts or {}
   local additional = build_header {
      is_none_match = opts.etag,
      if_modified_since = opts.last_modified,
   }
   url = url:gsub("rsshub:/", config.rsshub_instance)
   local dump_fp = vim.fn.tempname()
   local cmds = {
      "curl",
      "-sSL",
      "-D",
      dump_fp,
      "--connect-timeout",
      opts.timeout or 10,
      url,
   }
   cmds = vim.list_extend(cmds, additional)
   cmds = vim.list_extend(cmds, opts.cmds or {})
   pcall(spawn, cmds, url, dump_fp, cb)
end

M.get = fetch

M.fetch_co = ut.cb_to_co(fetch)

return M
