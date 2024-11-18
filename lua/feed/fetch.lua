local feedparser = require "feed.parser"
local ut = require "feed.utils"
local db = ut.require "feed.db"
local progress = require "feed.progress"

local M = {}
local feeds = db.feeds

---@param url string
---@param total integer
function M.update_feed(url, total)
   local tags, last_modified, etag
   if feeds[url] then
      last_modified = feeds[url].last_modified
      etag = feeds[url].etag
      tags = feeds[url].tags
   end
   local d = feedparser.parse(url, { timeout = 10, etag = etag, last_modified = last_modified })
   if not vim.tbl_isempty(d.entries) then
      for _, entry in ipairs(d.entries) do
         db:add(entry, tags)
      end
   end
   local href = d.href
   feeds[href].htmlUrl = feeds[href].htmlUrl or d.link
   feeds[href].title = feeds[href].title or d.title
   feeds[href].text = feeds[href].text or d.desc
   feeds[href].type = feeds[href].type or d.type
   feeds[href].tags = feeds[href].tags or tags -- TDOO: feed tags -- TODO: compare new tgs
   feeds[href].last_modified = d.last_modified
   feeds[href].etag = d.etag
   db:save_feeds()
   progress.advance(total, d.title or feeds[url].title or d.href)
end

-- FIX: update twice in one session no response
local c = 1
local function batch_update_feed(feedlist, size)
   -- TODO: progress.new
   for i = c, c + size - 1 do
      local v = feedlist[i]
      if not v then
         break
      end
      M.update_feed(v, #feedlist)
   end
   if c < #feedlist then
      vim.defer_fn(function()
         batch_update_feed(feedlist, size)
      end, 5000)
   else
      c = 1
   end
   c = c + size
end

M.batch_update_feed = batch_update_feed

return M
