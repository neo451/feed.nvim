local xml = require "feed.parser.xml"
local log = require "feed.lib.log"

---@alias feed.type "rss" | "atom" | "json"
---@alias feed.opml table<string, feed.feed | string>
---@alias feed.version "rss20" | "rss091" | "rss092" | "rss" | "atom10" | "atom03" | "json1"

---@class feed.feed
---@field title? string
---@field entries? feed.entry[] -> nil
---@field description? string -> title?
---@field htmlUrl? string
---@field type? feed.type
---@field tags? string[]
---@field last_modified? string
---@field etag? string
---@field version? feed.version

---@class feed.entry
---@field feed string
---@field link string
---@field time? integer -> os.time
---@field title? string -> "no title"
---@field author? string -> feed
---@field content? string -> "empty entry"
---@field tags? table<string, boolean>

local handle_rss = require "feed.parser.rss"
local handle_atom = require "feed.parser.atom"
local handle_json = require "feed.parser.jsonfeed"

local M = {}

---@param src string
---@param url string
---@return table?
function M.parse(src, url)
   local ret
   if vim.trim(src):sub(1, 1) == "{" then
      ret = handle_json(vim.json.decode(src, {
         luanil = {
            object = true
         }
      }), url)
      ret.encoding = ret.encoding or "utf-8"
      return ret
   else
      local raw_ast = xml.parse(src, url)
      if raw_ast then
         if raw_ast.rss or raw_ast["rdf:RDF"] then
            ret = handle_rss(raw_ast, url)
            ret.encoding = raw_ast.encoding or "utf-8"
         elseif raw_ast.feed then
            ret = handle_atom(raw_ast, url)
            ret.encoding = raw_ast.encoding or "utf-8"
         else
            log.warn(url, "unknown feedtype")
         end
         return ret
      end
   end
end

return M
