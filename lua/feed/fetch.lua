local curl = require "plenary.curl"
local config = require "feed.config"
local feedparser = require "feed.feedparser"
local db = require("feed.db").db(config.db_dir)

local M = {}

local function fetch(url, timeout, callback)
   -- TODO: pcall??? how to hanlde async errs?
   curl.get {
      url = url,
      timeout = timeout,
      callback = callback,
   }
end

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
      src = res.body
      local ok, ast = pcall(feedparser.parse, src)
      if not ok then -- FOR DEBUG
         print(("[feed.nvim] failed to parse %s"):format(feed.name or url))
         print(ast)
         return
      end
      local entries = ast.entries
      for _, entry in ipairs(entries) do
         db:add(entry)
      end
      db:save()
      if handle then
         handle.percentage = handle.percentage + 100 / total
         if handle.percentage == 100 then
            handle:finish()
         end
      end
   end
   fetch(url, 30000, callback)
end

-- TODO:  maybe use a process bar like fidget.nvim

return M
