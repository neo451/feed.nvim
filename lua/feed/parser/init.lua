local xml = require "feed.parser.xml"
local curl = require "feed.curl"
local log = require "feed.lib.log"

---@alias feed.type "rss" | "atom" | "json"
---@alias feed.opml table<string, feed.feed | string>

---@class feed.feed
---@field title? string
---@field text? string
---@field htmlUrl? string
---@field type? feed.type
---@field tags? string[]
---@field last_modified? string
---@field etag? string
---@field entries? feed.entry[]

---@class feed.entry
---@field time integer # falls back to the current os.time
---@field feed string # name of feed
---@field title string
---@field link? string # link to the entry
---@field author? string # falls back to the feed
---@field content? string
---@field tags? table<string, boolean>

local handle_rss = require "feed.parser.rss"
local handle_atom = require "feed.parser.atom"
local handle_json = require "feed.parser.jsonfeed"

local M = {}

---check if json
---@param str string
---@return boolean
local function is_json(str)
   return (vim.trim(str):sub(1, 1) == "{")
end

---Note:
---1. feed
--- 1.1 link/href link to homepage or xml
--- 1.2 title >> link
--- 1.3 desc >> title
--- 1.4 entries >> {}
--- 1.5 version
--- 1.6 type
---2. entry
--- 2.1 link
--- 2.2 feed
--- 2.3 title >> no title
--- 2.4 author >> feed.title
--- 2.5 time >> lastUpdated >> os.time()
--- 2.6 content >> "" -> resolve links in html

---@class feed.parser_opts
---@field etag? string
---@field last_modified? string
---@field timeout? integer

---@param src string
---@param url string
---@return table?
function M.parse_src(src, url)
   local ret
   if is_json(src) then
      ret = handle_json(vim.json.decode(src), url)
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

local valid_response = {
   [200] = true,
   [301] = true,
   [307] = true,
   [308] = true, -- TODO:
}

---parse feed fetch from source
---@param url string
---@param opts? feed.parser_opts
---@return table?
function M.parse(url, opts, cb)
   opts = opts or {}
   curl.get(function(response)
      if response then
         if response.body and response.body ~= "" and valid_response[response.status] then
            local ok, d = pcall(M.parse_src, response.body, url)
            if ok and d then
               return cb(vim.tbl_extend("keep", response, d))
            end
         end
         return cb(response)
      end
   end, url, opts)
end

return M
