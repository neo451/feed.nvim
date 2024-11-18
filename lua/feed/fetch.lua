local feedparser = require "feed.parser"
local ut = require "feed.utils"
local db = ut.require "feed.db"
local progress = require "feed.progress"

local M = {}

---fetch xml from source and load them into db
---@param url string
---@param total integer
function M.update_feed(url, total)
   local tags, last_modified, etag
   if db.feeds[url] then
      last_modified = db.feeds[url].last_modified
      etag = db.feeds[url].etag
      tags = db.feeds[url].tags
   end
   -- TODO: check if new tags from user config? getting to chaotic...
   local d = feedparser.parse(url, { timeout = 10, etag = etag, last_modified = last_modified })
   if not vim.tbl_isempty(d.entries) then
      for _, entry in ipairs(d.entries) do
         db:add(entry, tags)
      end
   end
   db.feeds[d.href].htmlUrl = d.link
   db.feeds[d.href].title = d.title
   db.feeds[d.href].text = d.desc
   db.feeds[d.href].type = d.type
   db.feeds[d.href].tags = tags -- TDOO: feed tags
   db.feeds[d.href].last_modified = d.last_modified
   db.feeds[d.href].etag = d.etag
   db:save_feeds()
   progress.advance(total, d.title or db.feeds[url] or d.href)
end

local c = 1
local function batch_update_feed(feeds, size)
   for i = c, c + size - 1 do
      local v = feeds[i]
      if not v then
         break
      end
      M.update_feed(v, #feeds)
   end
   if c < #feeds then
      vim.defer_fn(function()
         batch_update_feed(feeds, size)
      end, 5000)
   else
      c = 1
   end
   c = c + size
end

M.batch_update_feed = batch_update_feed

return M
