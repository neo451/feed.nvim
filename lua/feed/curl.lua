local M = {}
---@diagnostic disable: inject-field

---@class feed.curl.Opts
---@field headers? table<string, string>
---@field data? string|table
---@field etag? string
---@field last_modified? string
---@field timeout? string|integer
---@field cmds? string[]
---@field api? boolean

---@class feed.curl.Response: vim.SystemCompleted
---@field href? string
---@field etag? string
---@field last_modified? string
---@field status? integer
---@field headers? table<string, string>
---@field error? string

---@class feed.curl.WaitHandle
---@field wait fun(self: feed.curl.WaitHandle, timeout?: integer): feed.curl.Response

---@alias feed.curl.Handle vim.SystemObj|feed.curl.WaitHandle
local ut = require("feed.utils")
local log = require("feed.lib.log")
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
         local parsed = parse(sect)
         -- `curl -L` dumps one block per redirect (and proxies may add a
         -- CONNECT block). The body belongs to the final HTTP response.
         if parsed.status then
            headers = parsed
         end
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
---@param opts? feed.curl.Opts
---@param cb? fun(err: any?, response: feed.curl.Response?)
---@return feed.curl.Handle
function M.get(url, opts, cb)
   opts = opts or {}
   opts.timeout = opts.timeout or "10"
   opts.api = opts.api or false
   local req_header = build_header(vim.tbl_extend("keep", {
      is_none_match = opts.etag,
      if_modified_since = opts.last_modified,
      user_agent = "feed.nvim/2.0",
   }, opts.headers or {}))
   local dump_fp = vim.fn.tempname()
   local cmds = ut.tbl_flatten({
      "curl",
      req_header,
      "-sSL",
      "-D",
      dump_fp,
      "-A",
      "feed.nvim 2.0 (by /u/neoneo451)",
      opts.cmds,
      opts.timeout and { "--connect-timeout", opts.timeout or "10" },
      url,
   })
   ---@cast cmds string[]

   if opts.data then
      table.insert(cmds, "-d")
      if type(opts.data) == "table" then
         opts.data = vim.json.encode(opts.data)
      end
      table.insert(cmds, opts.data)
   end
   local process = function(obj)
      if obj.code == 0 then
         local headers = parse_header(dump_fp, url) or {}
         obj.href = headers.location or url
         obj.etag = headers.etag
         obj.last_modified = headers.last_modified
         obj.status = headers.status
         obj.headers = headers
         local content_type = headers.content_type
         ---@diagnostic disable-next-line: unnecessary-if
         if not opts.api and content_type and (not content_type:find("xml") and not content_type:find("json")) then
            obj.error = ("unexpected content type %q"):format(content_type)
         end
      else
         vim.uv.fs_unlink(dump_fp)
         log.warn("[feed.nvim]:", url, obj.stderr)
      end
      return obj
   end

   if cb then
      return vim.system(
         cmds,
         { text = true },
         vim.schedule_wrap(function(obj)
            local ok, result = xpcall(process, debug.traceback, obj)
            if not ok then
               cb(result, nil)
            elseif result.code ~= 0 then
               local detail = vim.trim(result.stderr or "")
               local err = ("curl failed with exit code %d"):format(result.code)
               cb(detail == "" and err or (err .. ": " .. detail), nil)
            else
               cb(nil, result)
            end
         end)
      )
   end

   return {
      wait = function(_, timeout)
         return process(vim.system(cmds, { text = true }):wait(timeout))
      end,
   }
end

return M
