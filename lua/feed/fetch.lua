local Feedparser = require "feed.parser"
local ut = require "feed.utils"
---@type feed.db
local db = ut.require "feed.db"
local Config = require "feed.config"

local M = {}
local feeds = db.feeds

local encoding_blacklist = {
   ["gb2312"] = true,
}

local valid_response = {
   [200] = true,
   [301] = true,
   [304] = true,
   [307] = true,
   [308] = true, -- TODO:
}

-- TODO: force_update option, ignore etag and last_modified

---@param url string
---@param opts { force: boolean }
function M.update_feed(url, opts, cb)
   local tags, last_modified, etag
   if feeds[url] and not opts.force then
      last_modified = feeds[url].last_modified
      etag = feeds[url].etag
      tags = vim.deepcopy(feeds[url].tags)
   end
   Feedparser.parse(url, { timeout = 10, etag = etag, last_modified = last_modified, cmds = Config.curl_params }, function(d)
      local ok = true
      if d then
         if d.status == 301 then -- permenantly moved
            feeds[url] = d.href -- to keep config consistent
            url = d.href
         elseif not valid_response[d.status] or encoding_blacklist[d.encoding] then
            feeds[url] = nil -- TODO: set to false
            ok = false
         end
         if d.entries and not vim.tbl_isempty(d.entries) then
            for _, entry in ipairs(d.entries) do
               db:add(entry, tags)
            end
         end
         feeds[url] = feeds[url] or {}
         -- TODO: tags and htmlUrl can change? --
         feeds[url].htmlUrl = feeds[url].htmlUrl or d.link
         feeds[url].title = feeds[url].title or d.title
         feeds[url].description = feeds[url].title or d.desc
         feeds[url].version = feeds[url].title or d.version
         feeds[url].tags = feeds[url].tags or tags -- TDOO: feed tags -- TODO: compare new tgs
         feeds[url].last_modified = d.last_modified
         feeds[url].etag = d.etag
         db:save_feeds()
      else
         ok = false
      end
      return cb(ok)
   end)
end

function M.update_all()
   local Promise = require "feed.lib.promise"
   local fetch = require "feed.fetch"

   local feeds = require("feed.db").feeds
   local list = require("feed.utils").feedlist(feeds)

   local function url2name(url)
      if feeds[url] then
         local feed = feeds[url]
         if feed.title then
            return feed.title or url
         end
      end
      return url
   end

   Promise.map(function(url)
      Promise.new(function(resolve, reject)
         fetch.update_feed(url, {}, function(ok)
            local name = url2name(url)
            io.write(table.concat({ name, (ok and " success" or " failed"), "\n" }, " "))
         end)
      end)
   end, list, 500)
end

return M
