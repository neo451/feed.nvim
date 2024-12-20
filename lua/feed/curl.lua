---@diagnostic disable: inject-field
local ut = require("feed.utils")
local log = require("feed.lib.log")
local Config = require("feed.config")
local coop_vim = require "coop.vim"

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

-- ---@param url string
-- ---@param opts table -- TODO:
-- ---@param cb? any
-- ---@return vim.SystemCompleted?
function M.get(url, opts, cb)
   assert(type(url) == "string", "url must be a string")
   opts = opts or {}
   local additional = build_header({
      is_none_match = opts.etag,
      if_modified_since = opts.last_modified,
   })
   local dump_fp = vim.fn.tempname()
   local cmds = {
      "curl",
      "-sSL",
      "-D",
      dump_fp,
      "--connect-timeout",
      opts.timeout or 10,
      url:find("rsshub:/") and url:gsub("rsshub:/", Config.rsshub_instance) .. "?format=json?mode=fulltext" or url,
   }
   cmds = vim.list_extend(cmds, additional)
   cmds = vim.list_extend(cmds, opts.cmds or {})
   if opts.data then
      table.insert(cmds, "-d")
      table.insert(cmds, vim.json.encode(opts.data))
   end
   local function process(obj)
      if obj.code == 0 then
         local headers = parse_header(dump_fp, url)
         obj.href = headers.location or url
         obj.etag = headers.etag
         obj.last_modified = headers.last_modified
         obj.status = headers.status
         obj.headers = headers
         if obj.stdout:find("<!DOCTYPE html>") then
            cb({ status = 404 })
            return
         end
         if cb then
            vim.schedule_wrap(cb)(obj)
         else
            return obj
         end
      else
         log.warn("[feed.nvim]:", url, obj.stderr)
      end
   end
   if cb then
      vim.system(cmds, { text = true }, process)
   else
      return process(vim.system(cmds, { text = true }):wait())
   end
end

-- M.get_co = ut.cb_to_co(M.get)

---@param url string
---@param opts table -- TODO:
---@return vim.SystemCompleted?
function M.get_co(url, opts)
   assert(type(url) == "string", "url must be a string")
   opts = opts or {}
   local additional = build_header({
      is_none_match = opts.etag,
      if_modified_since = opts.last_modified,
   })
   local dump_fp = vim.fn.tempname()
   local cmds = {
      "curl",
      "-sSL",
      "-D",
      dump_fp,
      "--connect-timeout",
      opts.timeout or 10,
      url:find("rsshub:/") and url:gsub("rsshub:/", Config.rsshub_instance) .. "?format=json?mode=fulltext" or url,
   }
   cmds = vim.list_extend(cmds, additional)
   cmds = vim.list_extend(cmds, opts.cmds or {})
   if opts.data then
      table.insert(cmds, "-d")
      table.insert(cmds, vim.json.encode(opts.data))
   end
   local obj = coop_vim.system(cmds, { text = true })
   if obj.code == 0 then
      local headers = parse_header(dump_fp, url)
      obj.href = headers.location or url
      obj.etag = headers.etag
      obj.last_modified = headers.last_modified
      obj.status = headers.status
      obj.headers = headers
      if obj.stdout:find("<!DOCTYPE html>") then
         return
      end
      return obj
   else
      log.warn("[feed.nvim]:", url, obj.stderr)
   end
end

return M
