local date = require("feed.parser.date")
local ut = require("feed.utils")
local sensible = ut.sensible
local decode = ut.decode
local resolve = require("feed.parser.html").resolve

local function handle_title(node)
   if not node.title then
      return "no title"
   end
   return decode(node.title)
end

local function handle_author(ast, feed_name)
   return sensible(ast.author, "name", feed_name)
end

---@param entry table
---@param feed feed.feed
---@return table
local handle_entry = function(entry, feed, url)
   local res = {}
   res.link = entry.url
   res.content = resolve(entry.content_html or "", feed.link)
   res.time = date.parse(entry.date_published, "json")
   res.title = handle_title(entry)
   res.author = decode(feed.author)
   res.feed = url
   return res
end

return function(ast, url) -- no link resolve for now only do html link resolve later
   local res = {}
   res.version = "json1"
   res.link = ast.home_page_url or ast.feed_url or url
   res.title = handle_title(ast)
   res.desc = decode(ast.description or res.title)
   res.author = decode(handle_author(ast, res.title))
   res.entries = {}
   res.type = "json"
   if ast.items then
      for _, v in ipairs(ut.listify(ast.items)) do
         res.entries[#res.entries + 1] = handle_entry(v, res, url)
      end
   end
   return res
end
