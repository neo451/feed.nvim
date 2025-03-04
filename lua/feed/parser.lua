---@alias feed.opml table<string, feed.feed | boolean>
---@alias feed.version "rss20" | "rss091" | "rss092" | "rss" | "atom10" | "atom03" | "json1"

---@class feed.feed
---@field link string
---@field htmlUrl string
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
---@field time integer -> os.time
---@field title string -> "no title"
---@field author? string
---@field content? string -> ""
---@field tags? table<string, boolean>

local M = {}
local xml = require("feed.parser.xml")
local log = require("feed.lib.log")
local ut = require("feed.utils")

---@param src string
---@param url string
---@return feed.feed
local function parse_src(src, url)
   if vim.startswith(vim.trim(src), "{") then
      local ast = vim.json.decode(src, { luanil = { object = true } })
      return require("feed.parser.json")(ast, url)
   else
      local ast = xml.parse(src, url)
      if ast then
         if ast["rss"] or ast["rdf:RDF"] then
            return require("feed.parser.rss")(ast, url)
         elseif ast["feed"] then
            return require("feed.parser.atom")(ast, url)
         else
            log.warn(url, "unknown feedtype")
         end
      end
   end
end

local valid_response = ut.list2lookup({ 200, 301, 302, 303, 304, 307, 308 })
local encoding_blacklist = ut.list2lookup({ "gb2312" })

---process feed fetch from source
---@param url_or_src  string
---@param opts? { etag?: string, last_modified?: string, timeout?: integer }
---@return feed.feed | vim.SystemCompleted | { href: string, status: integer, encoding: string }
---@async
function M.parse(url_or_src, opts)
   opts = opts or {}

   if ut.looks_like_url(url_or_src) then
      local Curl = require("feed.curl")
      local response = Curl.get_co(url_or_src, opts)
      if response and response.stdout and valid_response[response.status] then
         local d = parse_src(response.stdout, url_or_src)
         if d then
            return vim.tbl_extend("keep", response, d)
         end
      end
      return response
   else
      return parse_src(url_or_src, opts.url) -- TODO:
   end
end

return M
