---@diagnostic disable: inject-field
local ut = require("feed.utils")
local log = require("feed.lib.log")

local github = require("feed.integrations.github")
local rsshub = require("feed.integrations.rsshub")

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
      res[#res + 1] = ("'%s: %s'"):format(upper(k:gsub("_", "%-")), v)
   end
   return res
end

---@param url string
---@param opts table
---@param cb? any
function M.get(url, opts, cb)
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
      opts.timeout or "10",
      rsshub(github(url)),
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
         local content_type = headers.content_type

         if content_type and (not content_type:find("xml") and not content_type:find("json")) then
            return { status = 404 } -- ?
         end
         vim.schedule_wrap(cb)(obj)
      else
         log.warn("[feed.nvim]:", url, obj.stderr)
      end
   end
   return vim.system(cmds, { text = true }, process)
end

local task_utils = require("coop.task-utils")
local f_utils = require("coop.functional-utils")

---@async
M.get_co = task_utils.cb_to_tf(f_utils.shift_parameters(M.get))

return M
