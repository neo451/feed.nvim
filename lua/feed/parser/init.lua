local xml = require("feed.parser.xml")
local log = require("feed.lib.log")

---@alias feed.type "rss" | "atom" | "json"
---@alias feed.opml table<string, feed.feed | boolean>
---@alias feed.version "rss20" | "rss091" | "rss092" | "rss" | "atom10" | "atom03" | "json1"

---@class feed.feed
---@field link string
---@field title string
---@field entries? feed.entry[] -> nil
---@field desc? string
---@field htmlUrl? string
---@field type? feed.type
---@field tags? string[]
---@field last_modified? string
---@field etag? string
---@field version? feed.version
---@field author? string

---@class feed.entry
---@field feed string url to the feed
---@field link string url to the entry
---@field time? integer -> os.time
---@field title? string -> "no title"
---@field author? string -> feed
---@field content? string -> ""
---@field tags? table<string, boolean>

local handle_rss = require("feed.parser.rss")
local handle_atom = require("feed.parser.atom")
local handle_json = require("feed.parser.jsonfeed")

local M = {}

---@param src string
---@param url string
---@return table?
function M.parse(src, url)
   if vim.startswith(vim.trim(src), "{") then
      local ast = vim.json.decode(src, { luanil = { object = true } })
      return handle_json(ast, url)
   else
      local ast = xml.parse(src, url)
      if ast then
         if ast["rss"] or ast["rdf:RDF"] then
            return handle_rss(ast, url)
         elseif ast["feed"] then
            return handle_atom(ast, url)
         else
            log.warn(url, "unknown feedtype")
         end
      end
   end
end

return M
