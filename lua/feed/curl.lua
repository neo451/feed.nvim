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
---@param opts { headers: table, data: string | table, etag: string, last_modified: string, timeout: string, cmds: table }
---@param cb? any
function M.get(url, opts, cb)
   opts = opts or {}
   opts.timeout = vim.F.if_nil(opts.timeout, "10")
   opts.api = vim.F.if_nil(opts.api, false)
   local req_header = build_header(vim.tbl_extend("keep", {
      is_none_match = opts.etag,
      if_modified_since = opts.last_modified,
   }, opts.headers or {}))
   local dump_fp = vim.fn.tempname()
   local cmds = vim.tbl_flatten({
      "curl",
      req_header,
      "-sSL",
      "-D",
      dump_fp,
      opts.cmds,
      opts.timeout and { "--connect-timeout", opts.timeout or "10" },
      rsshub(github(url)),
   })
   if opts.data then
      table.insert(cmds, "-d")
      if type(opts.data) == "table" then
         opts.data = vim.json.encode(opts.data)
      end
      table.insert(cmds, opts.data)
   end
   local process = function(obj)
      cb = cb and vim.schedule_wrap(cb)
      if obj.code == 0 then
         local headers = parse_header(dump_fp, url)
         obj.href = headers.location or url
         obj.etag = headers.etag
         obj.last_modified = headers.last_modified
         obj.status = headers.status
         obj.headers = headers
         local content_type = headers.content_type

         if not opts.api and content_type and (not content_type:find("xml") and not content_type:find("json")) then
            obj = { status = 404 }
         end
      else
         log.warn("[feed.nvim]:", url, obj.stderr)
      end
      return cb and cb(obj) or obj
   end

   return cb and vim.system(cmds, { text = true }, cb and process or nil)
      or process(vim.system(cmds, { text = true }):wait())
end

local task_utils = require("coop.task-utils")
local f_utils = require("coop.functional-utils")

---@async
M.get_co = task_utils.cb_to_tf(f_utils.shift_parameters(M.get))

return M
