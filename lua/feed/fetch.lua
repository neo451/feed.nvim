local curl = require "plenary.curl"
local config = require "feed.config"
local feedparser = require "feed.feedparser"
local date = require "feed.date"
local db = require("feed.db").db(config.db_dir)
local sha1 = require "feed.sha1"

local M = {}

---@param ast table
---@param feed_type feed.feedtype
---@return feed.entry[]
---@return string
local function get_root(ast, feed_type)
   if feed_type == "json" then
      return ast.items, ast.title
   elseif feed_type == "rss" then
      return ast.channel.item, ast.channel.title
   else
      return {}, "nulllll" --- TODO: test atom feeds!!!
   end
end

local date_tag = {
   rss = "pubDate",
   json = "date_published",
}

---@param entry table
---@param feedtype feed.feedtype
---@param feedname string
---@return feed.entry
---@return string # content to store on disk
local function unify(entry, feedtype, feedname)
   local content
   local _date = entry[date_tag[feedtype]]
   entry[date_tag[feedtype]] = nil
   entry.time = date.new_from[feedtype](_date):absolute()
   entry.feed = feedname
   entry.tags = { unread = true } -- HACK:
   if feedtype == "json" then
      entry.link = entry.url
      entry.id = sha1(entry.link)
      entry.url = nil
      content = entry.content_html
      content = content:gsub("\n", "") -- HACK:
      entry.content_html = nil
   elseif feedtype == "rss" then
      entry.link = entry.link
      entry.id = sha1(entry.link)
      content = entry["content:encoded"] or entry.description
      content = content:gsub("\n", "") -- HACK:
      entry["content:encoded"] = nil
      entry.description = nil
   end
   return entry, content
end

function M.fetch(url, timeout, callback)
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
      url = feed[1]
   else
      url = feed
   end
   local function callback(res)
      if res.status ~= 200 then
         return
      end
      src = (res.body):gsub("\n", "") -- HACK:
      local ok, ast, feed_type = pcall(feedparser.parse, src)
      if not ok then                  -- FOR DEBUG
         print(("[feed.nvim] failed to parse %s"):format(feed.name or url))
         print(ast)
         return
      end
      local entries, feed_name = get_root(ast, feed_type)
      for _, entry in ipairs(entries) do
         db:add(unify(entry, feed_type, feed_name))
      end
      db:save()
      if handle then
         handle.percentage = handle.percentage + 100 / total
         if handle.percentage == 100 then
            handle:finish()
         end
      end
   end
   M.fetch(url, 30000, callback)
end

-- TODO:  maybe use a process bar like fidget.nvim

return M
