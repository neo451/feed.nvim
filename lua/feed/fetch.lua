local parser = require("feed.parser")
local config = require("feed.config")
local ut = require("feed.utils")
local db = require("feed.db")
local M = {}

local valid_response = ut.list2lookup({ 200, 301, 302, 303, 304, 307, 308 })
local encoding_blacklist = ut.list2lookup({ "gb2312" })

---update a feed and add it to db
---@param url string
---@param opts { force: boolean }
---@async
function M.update_feed(url, opts)
   local feeds = db.feeds
   local last_modified, etag, tags
   if feeds[url] and not opts.force then
      last_modified = feeds[url].last_modified
      etag = feeds[url].etag
   end

   tags = feeds[url] and feeds[url].tags

   local d = parser.parse(
      ut.extend_import_url(url),
      { last_modified = last_modified, etag = etag, timeout = 10, cmds = config.curl_params }
   )
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
      db[id] = entry
      ut.save_file(fp, content)
      if tags then
         db:tag(id, tags)
      end
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

   return true -- TODO: maybe return a status: "ok" | "err" | "moved" ?
end

---update all feeds
---@async
function M.update()
   local Coop = require("coop")
   local feeds = db.feeds
   local c = 0
   local list = ut.feedlist(feeds, false)
   local n = #list

   if n == 0 then
      print("Empty database\n")
      os.exit()
   end

   for i = 1, n do
      Coop.spawn(function()
         local url = list[i]
         local ok = M.update_feed(url, { force = false })
         local name = ut.url2name(url, feeds)
         c = c + 1
         print(string.format("[%s/%s]", c, n), name, ok and config.progress.ok or config.progress.err)
         print("\n")
         if c == n then
            os.exit()
         end
      end)
   end
end

return M
