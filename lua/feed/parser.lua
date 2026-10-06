---@alias feed.opml table<string, feed.feedMetadata|false>
---@alias feed.version "rss20" | "rss091" | "rss092" | "rss" | "atom10" | "atom03" | "json1"

---@class feed.feedMetadata
---@field htmlUrl? string
---@field title? string
---@field desc? string
---@field tags? string[]
---@field last_modified? string
---@field etag? string
---@field version? feed.version

---@class feed.feed
---@field link string
---@field htmlUrl? string
---@field title string
---@field entries feed.entry[]
---@field desc? string
---@field tags? string[]
---@field last_modified? string
---@field etag? string
---@field version? feed.version
---@field author? string

---@class feed.entry
---@field feed string url to the feed
---@field link string url to the entry
---@field time integer Unix timestamp from os.time
---@field title string Defaults to "no title"
---@field author? string
---@field content? string|fun(): string Defaults to an empty string
---@field tags? table<string, boolean>
---@field id? string reference in the db, only exists if entry is produced by get_entry, else not stored in the object

local M = {}
local xml = require("feed.parser.xml")
local log = require("feed.lib.log")
local ut = require("feed.utils")
local url_util = require("feed.url")

---@param src string
---@param url string
---@return feed.feed?
---@return string?
local function parse_src(src, url)
   if vim.startswith(vim.trim(src), "{") then
      local ast = vim.json.decode(src, { luanil = { object = true } })
      return require("feed.parser.json")(ast, url)
   else
      local ast = xml.parse(src, url)
      if not ast then
         return nil, "invalid XML"
      elseif ast["rss"] or ast["rdf:RDF"] then
         return require("feed.parser.rss")(ast, url)
      elseif ast["feed"] then
         return require("feed.parser.atom")(ast, url)
      else
         log.warn(url, "unknown feed type")
         return nil, "unsupported XML feed type"
      end
   end
end

local valid_response = ut.list2lookup({ 200, 301, 302, 303, 304, 307, 308 })
-- local encoding_blacklist = ut.list2lookup({ "gb2312" })

---Process a feed fetched from a URL.
---@param url string
---@param opts? feed.curl.Opts
---@param cb fun(err: any?, result: feed.feed|feed.curl.Response?)
---@return feed.curl.Handle?
function M.parse(url, opts, cb)
   opts = opts or {}
   assert(type(cb) == "function", "feed.parse requires a callback")
   local called = false
   local finish = function(err, result)
      if called then
         return
      end
      called = true
      cb(err, result)
   end

   local Curl = require("feed.curl")
   local ok, handle = xpcall(function()
      return Curl.get(url_util.extend_import_url(url), opts, function(err, response)
         if err then
            finish(err, nil)
            return
         end

         local parsed, result, parse_err = xpcall(function()
            if not response then
               return nil, "request returned no response"
            elseif not response.status then
               return nil, "request returned no HTTP status"
            elseif not valid_response[response.status] then
               return nil, ("request failed with HTTP status %d"):format(response.status)
            elseif response.status == 304 then
               return response
            elseif response.error then
               return nil, response.error
            elseif not response.stdout or vim.trim(response.stdout) == "" then
               return nil, "feed response was empty"
            end

            local d, reason = parse_src(response.stdout, url)
            if not d then
               return nil, "failed to parse feed: " .. (reason or "unknown format")
            end
            return vim.tbl_extend("keep", response, d)
         end, debug.traceback)

         if not parsed then
            finish(result, nil)
         elseif not result then
            finish(parse_err, nil)
         else
            finish(nil, result)
         end
      end)
   end, debug.traceback)

   if ok then
      return handle
   end
   finish(handle, nil)
end

M.parse_src = parse_src

return M
