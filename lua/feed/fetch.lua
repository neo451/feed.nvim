local curl = require "plenary.curl"
local config = require "feed.config"
local feedparser = require "feed.feedparser"
local date = require "feed.date"
local db = require("feed.db").db(config.db_dir)

local M = {}

---@param ast table
---@param feed_type feed.feedtype
---@return feed.entry[]
---@return string
local function get_root(ast, feed_type)
   if feed_type == "json" then
      return ast.items, ast.title
   elseif feed_type == "rss" then
      return ast.item, ast.title
   else
      return {}, "nulllll" --- TODO: test atom feeds!!!
   end
end

local date_tag = {
   rss = "pubDate",
   json = "date_published",
}

--- TODO: put the logic elsewhere
-- local content = entry["content:encoded"] or entry.description

---@param entry table
---@param feedtype feed.feedtype
---@param feedname string
---@return feed.entry
local function unify(entry, feedtype, feedname)
   local _date = entry[date_tag[feedtype]]
   entry[date_tag[feedtype]] = nil
   entry.time = date.new_from[feedtype](_date):absolute()
   entry.feed = feedname
   entry.tags = { unread = true } -- HACK:
   if feedtype == "json" then
      entry.link = entry.url
      entry.url = nil
      entry.description = entry.content_html
      entry.content_html = nil
   end
   return entry
end

---fetch xml from source and load them into db
---@param feed feed.feed
---@param total number # total number of feeds
---@param index number # index of the feed
function M.update_feed(feed, total, index)
   local url
   if type(feed) == "table" then
      url = feed[1]
   else
      url = feed
   end
   curl.get {
      url = url,
      timeout = 50000,
      callback = function(res)
         if res.status ~= 200 then
            return
         end
         local src = (res.body):gsub("\n", "") -- HACK:
         local ok, ast, feed_type = pcall(feedparser.parse, src)
         if not ok then                        -- FOR DEBUG
            print(("[feed.nvim] failed to parse %s"):format(feed.name or url))
            print(ast)
            return
         end
         local entries, feed_name = get_root(ast, feed_type)
         for _, entry in ipairs(entries) do
            db:add(unify(entry, feed_type, feed_name))
         end
         db:save()
         print(("%d/%d"):format(index, total))
      end,
   }
end

-- TODO:  vim.notify("feeds all loaded")
-- TODO:  maybe use a process bar like fidget.nvim

return M
