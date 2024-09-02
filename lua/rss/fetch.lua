local config = require "rss.config"
local flatdb = require "rss.db"
local xml = require "rss.xml"
local curl = require "rss.curl"
local db = flatdb(config.db_dir)
local date = require "rss.date"

local M = {}

---@param ast table
---@param feed_type rss.feed_type
---@return rss.entry[]
---@return string
local function get_root(ast, feed_type)
   if feed_type == "json" then
      return ast.items, ast.title
   elseif feed_type == "rss" then
      return ast.channel.item, ast.title
   else
      return {}, "nulllll"
   end
end

local date_tag = {
   rss = "pubDate",
   json = "date_published",
}

--- TODO: put the logic elsewhere
-- local content = entry["content:encoded"] or entry.description
--
---@param entry table
---@param feedtype rss.feed_type
---@param feedname string
---@return rss.entry
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
---@param feed rss.feed
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
      callback = function(res)
         if res.status ~= 200 then
            return
         end
         local src = res.body
         local ok, ast, feed_type = pcall(xml.parse_feed, src)
         pp(ast)
         if not ok then -- FOR DEBUG
            print(("[rss.nvim] failed to parse %s"):format(feed.name or url))
            return
         end
         local entries, feed_name = get_root(ast, feed_type)
         for _, entry in ipairs(entries) do
            db:add(unify(entry, feed_type, feed_name))
         end
         db:save()
      end,
   }
end

-- TODO:  vim.notify("feeds all loaded")
-- TODO:  maybe use a process bar like fidget.nvim

return M
