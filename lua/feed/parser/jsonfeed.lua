local date = require("feed.parser.date")
local ut = require("feed.utils")
local clean = ut.clean
local resolve = require("feed.parser.html").resolve

local function handle_title(node, fallback)
   if not node.title then
      return fallback
   end
   return clean(node.title)
end

local function handle_author(ast, fallback)
   if not ast.author then
      return fallback
   end
   return clean(ast.author.name)
end

---@param entry table
---@param feed feed.feed
---@return table
local handle_entry = function(entry, feed, url)
   local res = {}
   res.link = entry.url
   res.content = resolve(entry.content_html or "", feed.link)
   res.time = date.parse(entry.date_published, "json")
   res.title = handle_title(entry, "no title")
   res.author = clean(feed.author)
   res.feed = url
   return res
end

return function(ast, url)
   local res = {}
   res.version = "json1"
   res.link = ast.home_page_url or ast.feed_url or url
   res.title = handle_title(ast, res.link)
   res.desc = clean(ast.description or res.title)
   res.author = handle_author(ast, res.title)
   res.entries = {}
   if ast.items then
      for _, v in ipairs(ut.listify(ast.items)) do
         res.entries[#res.entries + 1] = handle_entry(v, res, url)
      end
   end
   return res
end
