local Coop = require("coop")
local Feedparser = require("feed.parser")
local Curl = require("feed.curl")
local Config = require("feed.config")
local Markdown = require("feed.ui.markdown")
local db = require("feed.db")
local ut = require("feed.utils")
local M = {}
local as_completed = require("coop.control").as_completed

local valid_response = ut.list2lookup({ 200, 301, 302, 303, 304, 307, 308 })
local encoding_blacklist = ut.list2lookup({ "gb2312" })

--- process feed fetch from source
---@param url string
---@param opts? { etag?: string, last_modified?: string, timeout?: integer }
---@return feed.feed | vim.SystemCompleted | { href: string, status: integer, encoding: string }
---@async
local function parse_co(url, opts)
   opts = opts or {}
   local response = Curl.get_co(url, opts)
   if response and response.stdout and valid_response[response.status] then
      local d = Feedparser.parse(response.stdout, url)
      if d then
         return vim.tbl_extend("keep", response, d)
      end
   end
   return response
end

--- update a feed and load it to db
---@param url string
---@param opts { force: boolean }
---@async
function M.update_feed_co(url, opts)
   local feeds = db.feeds
   local last_modified, etag
   if feeds[url] and not opts.force then
      last_modified = feeds[url].last_modified
      etag = feeds[url].etag
   end

   local d = parse_co(url, { last_modified = last_modified, etag = etag, timeout = 10, cmds = Config.curl_params })
   if not d then
      return false
   end
   if d.status == 301 or d.status == 308 then
      feeds[url] = false
      url = ut.url_resolve(url, d.href)
   elseif not valid_response[d.status] or encoding_blacklist[d.encoding] then
      feeds[url] = nil
      return false
   end

   for _, entry in ipairs(d.entries or {}) do
      local content = entry.content
      entry.content = nil
      local id = vim.fn.sha256(entry.link)
      local fp = tostring(db.dir / "data" / id)
      Markdown.convert({
         src = content,
         cb = function() end,
         fp = fp,
      })
      db[id] = entry
   end

   feeds[url] = feeds[url] or {}
   local feed = feeds[url]

   feed.htmlUrl = feed.htmlUrl or d.link
   feed.title = feed.title or d.title
   feed.desc = feed.desc or d.desc
   feed.version = feed.version or d.version

   feed.last_modified = d.last_modified
   feed.etag = d.etag
   db:save_feeds()
   return true
end

--- update all feeds
---@async
function M.update_all()
   local feeds = db.feeds
   local c = 0
   local list = ut.feedlist(feeds, false)
   local n = #list

   for i = 1, n do
      Coop.spawn(function()
         local url = list[i]
         local ok = M.update_feed_co(url, { force = false })
         local name = ut.url2name(url, feeds)
         c = c + 1
         print(name, ok and "success" or "failed", "\n")
         if c == n then
            os.exit()
         end
      end)
   end
end

return M
