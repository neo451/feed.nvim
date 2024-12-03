local feedparser = require "feed.parser"
local ut = require "feed.utils"
---@type feed.db
local db = ut.require "feed.db"
local progress = require "feed.ui.progress"
local log = require "feed.lib.log"
local run = ut.run
local entities = require "feed.lib.entities"
local decode = entities.decode
local config = require "feed.config"
local ui = require "feed.ui"

local M = {}
local feeds = db.feeds

local encoding_blacklist = {
   ["gb2312"] = true,
}

-- TODO: force_update option, ignore etag and last_modified

---@param url string
---@param opts { force: boolean }
---@return  boolean
function M.update_feed(url, opts)
   local tags, last_modified, etag
   if feeds[url] and not opts.force then
      last_modified = feeds[url].last_modified
      etag = feeds[url].etag
      tags = vim.deepcopy(feeds[url].tags)
   end
   local ok, d = pcall(feedparser.parse, url, { timeout = 10, etag = etag, last_modified = last_modified, cmds = config.curl_params })
   if ok and d then
      if d.status == 301 then -- permenantly moved
         feeds[url] = d.href -- to keep config consistent
         url = d.href
      elseif d.status == 304 then
         return true
      elseif d.status == 404 or encoding_blacklist[d.encoding] then
         feeds[url] = nil
         return false
      end
      if not vim.tbl_isempty(d.entries) then
         for _, entry in ipairs(d.entries) do
            db:add(entry, tags)
         end
      end
      feeds[url] = feeds[url] or {}
      feeds[url].htmlUrl = d.link
      feeds[url].title = decode(d.title) or d.title
      feeds[url].description = decode(d.desc) or d.desc
      feeds[url].version = d.version
      feeds[url].tags = tags -- TDOO: feed tags -- TODO: compare new tgs
      feeds[url].last_modified = d.last_modified
      feeds[url].etag = d.etag
      db:save_feeds()
      return true
   end
   return false
end

local function url2name(url)
   if feeds[url] then
      local feed = feeds[url]
      if feed.title then
         return feed.title or url
      end
   end
   return url
end

---@param feedlist string[]
---@param size integer
---@param opts table
function M.update_feeds(feedlist, size, opts)
   local prog = progress.new(#feedlist)
   local function aux(i)
      for j = i, i + size do
         local url = feedlist[j]
         if not url then
            if ut.in_index() then
               ui.refresh()
            end
            return
         end
         run(function()
            local d = M.update_feed(url, opts)
            local name = url2name(url)
            if d then
               prog:update(name .. " success")
            else
               prog:update(name .. " failed")
               log.warn(url, "failed")
            end
            if j == i + size then
               aux(i + size + 1)
            end
         end)
      end
   end
   aux(1)
end

-- local uv = vim.uv
--
-- ---@param feedlist string[]
-- ---@param size integer
-- function M.update_feeds(feedlist, size)
--    local ctx = uv.new_work(function(url)
--       print(url)
--       -- local progress = require "feed.progress"
--       -- local prog = progress.new(#feedlist)
--       -- local run = require("feed.utils").run
--       -- run(function()
--       --    local ok, d = pcall(M.update_feed, url)
--       --    local name = url_to_name(url, d)
--       --    if ok then
--       --       prog:update(name .. " success")
--       --    else
--       --       prog:update(name .. " failed")
--       --       log.warn(url, d)
--       --    end
--       -- end)
--    end, function() end)
--
--    for i = 1, #feedlist do
--       uv.queue_work(ctx, feedlist[i])
--    end
-- end

return M
