local feedparser = require "feed.parser"
local ut = require "feed.utils"
---@type feed.db
local db = ut.require "feed.db"
local progress = require "feed.progress"
local log = require "feed.lib.log"
local run = ut.run
local entities = require "feed.lib.entities"
local decode = entities.decode

local M = {}
local feeds = db.feeds

local encoding_blacklist = {
   ["gb2312"] = true,
}

-- TODO: force_update option, ignore etag and last_modified

---@param url string
---@return table?
function M.update_feed(url, opts)
   local tags, last_modified, etag
   if feeds[url] then
      last_modified = feeds[url].last_modified
      etag = feeds[url].etag
      tags = vim.deepcopy(feeds[url].tags)
   end
   local ok, d = pcall(feedparser.parse, url, { timeout = 10, etag = etag, last_modified = last_modified })
   if ok and d then
      if encoding_blacklist[d.encoding] then
         feeds[url] = nil
         db:save_feeds()
         return { title = url }
      end
      if not vim.tbl_isempty(d.entries) then
         for _, entry in ipairs(d.entries) do
            db:add(entry, tags)
         end
      end
      local href = d.href
      if not feeds[href] then
         feeds[href] = {}
      end
      if href ~= url then
         feeds[url] = href
      end
      feeds[href].htmlUrl = feeds[href].htmlUrl or d.link
      feeds[href].title = feeds[href].title or d.title
      feeds[href].text = feeds[href].text or d.desc
      feeds[href].type = feeds[href].type or d.type
      feeds[href].tags = feeds[href].tags or tags -- TDOO: feed tags -- TODO: compare new tgs
      feeds[href].last_modified = d.last_modified
      feeds[href].etag = d.etag
      db:save_feeds()
      return d
   end
end

local function url_to_name(url, d)
   if d then
      if d.title then
         return decode(d.title)
      else
         return d.href
      end
   end
   if feeds[url] then
      return decode(feeds[url].title or feeds[url].text)
   end
   return url
end

---@param feedlist string[]
---@param size integer
function M.update_feeds(feedlist, size)
   local prog = progress.new(#feedlist)
   local function aux(i)
      for ii = i, i + size do
         local url = feedlist[ii]
         if not url then
            return
         end
         run(function()
            local ok, d = pcall(M.update_feed, url)
            local name = url_to_name(url, d)
            if ok then
               prog:update(name .. " success")
            else
               prog:update(name .. " failed")
               log.warn(url, d)
            end
            if ii == i + size then
               aux(i + size + 1)
            end
         end)
      end
   end
   aux(1)
end

return M
