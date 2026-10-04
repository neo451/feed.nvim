local parser = require("feed.parser")
local config = require("feed.config")
local ut = require("feed.utils")
local db = require("feed.db")
local log = require("feed.lib.log")
local M = {}

local valid_response = ut.list2lookup({ 200, 301, 302, 303, 304, 307, 308 })
local encoding_blacklist = ut.list2lookup({ "gb2312" })

---Update a feed and add it to the database.
---@param url string
---@param opts { force: boolean }
---@param cb fun(err: any?, updated: boolean)
---@return vim.SystemObj
function M.update_feed(url, opts, cb)
   assert(type(cb) == "function", "feed.fetch.update_feed requires a callback")
   local called = false
   local finish = function(err, updated)
      if called then
         return
      end
      called = true
      cb(err, updated)
   end

   local feeds = db.feeds
   local last_modified, etag, tags
   if feeds[url] and not opts.force then
      last_modified = feeds[url].last_modified
      etag = feeds[url].etag
   end

   tags = feeds[url] and feeds[url].tags

   return parser.parse(
      url,
      { last_modified = last_modified, etag = etag, timeout = 10, cmds = config.curl_params },
      function(err, d)
         if err then
            finish(err, false)
            return
         end

         local ok, updated = xpcall(function()
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

            return true
         end, debug.traceback)

         if ok then
            finish(nil, updated)
         else
            finish(updated, false)
         end
      end
   )
end

---Update all feeds concurrently.
---@param on_complete? fun(err: any?)
---@return vim.SystemObj[]
function M.update(on_complete)
   local feeds = db.feeds
   local completed = 0
   local first_error
   local list = ut.feedlist(feeds, false)
   local total = #list
   local handles = {}

   local finish = function()
      if on_complete then
         on_complete(first_error)
      else
         os.exit(first_error and 1 or 0)
      end
   end

   if total == 0 then
      print("Empty database\n")
      finish()
      return handles
   end

   for _, url in ipairs(list) do
      local feed_url = url
      local settled = false
      local complete = function(err, updated)
         if settled then
            return
         end
         settled = true

         if err then
            first_error = first_error or err
            log.warn(feed_url, err)
         end

         completed = completed + 1
         local name = ut.url2name(feed_url, feeds)
         print(string.format("[%s/%s]", completed, total), name, updated and config.progress.ok or config.progress.err)
         print("\n")
         if completed == total then
            finish()
         end
      end

      local ok, handle = xpcall(function()
         return M.update_feed(feed_url, { force = false }, complete)
      end, debug.traceback)
      if ok then
         handles[#handles + 1] = handle
      else
         complete(handle, false)
      end
   end

   return handles
end

return M
