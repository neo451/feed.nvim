local curl = require "plenary.curl"
local feedparser = require "feed.feedparser"
local db = require "feed.db"

local M = {}

local function check_rsshub(_)
   return false -- TODO:
end

local function fetch(url, timeout, callback, is_rsshub)
   if is_rsshub == nil then
      is_rsshub = check_rsshub(url)
   end
   curl.get {
      url = url,
      timeout = timeout,
      callback = callback,
      query = is_rsshub and { format = "json" } or nil,
      on_error = function(err)
         print(err.message)
         return err.message
      end,
   }
end
local config = require "feed.config"
local opml = require "feed.opml"
local feeds = opml.import(config.db_dir .. "/feeds.opml")

---fetch xml from source and load them into db
---@param feed feed.feed
---@param total number # total number of feeds
---@param handle ProgressHandle
function M.update_feed(feed, total, handle)
   local src
   local url
   if type(feed) == "table" then
      if feed.xmlUrl then
         url = feed.xmlUrl
      else
         url = feed[1]
      end
   else
      url = feed
   end
   local function callback(res)
      if res.status ~= 200 then
         return
      end
      src = res.body:gsub("\n", "")
      local ok, ast = pcall(feedparser.parse, src)
      feeds:append { xmlUrl = url, htmlUrl = ast.link, title = ast.title, text = ast.title }
      feeds:export(config.db_dir .. "/feeds.opml")
      if not ok then
         print(("[feed.nvim] failed to parse %s"):format(feed.name or url))
         print(ast)
         return
      end
      local entries = ast.entries
      for _, entry in ipairs(entries) do
         db:add(entry)
      end
      -- TODO: update the local ompl here
      db:save()
      if handle then
         handle.percentage = handle.percentage + 100 / total
         if handle.percentage == 100 then
            handle:finish()
         end
      end
   end
   fetch(url, 300, callback, nil) --TODO:
end

return M
