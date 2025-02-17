local date = require("feed.parser.date")
local ut = require("feed.utils")
local p_ut = require("feed.parser.utils")
local sensible = p_ut.sensible
local decode = require("feed.lib.entities").decode

local function handle_title(entry)
   if not entry.title then
      return "no title"
   end
   return entry.title
end

local function handle_entry(entry, author, feed_name, feed_url, url_id)
   local res = {}
   res.link = entry.url
   res.content = entry.content_html or ""
   res.time = date.parse(entry.date_published, "json")
   res.title = decode(handle_title(entry))
   res.author = decode(author)
   res.feed = url_id
   return res
end

local function handle_author(ast, feed_name)
   return sensible(ast.author, "name", feed_name)
end

return function(ast, url) -- no link resolve for now only do html link resolve later
   local res = {}
   res.version = "json1"
   res.link = ast.home_page_url or ast.feed_url
   res.title = decode(ast.title)
   res.desc = decode(ast.description or res.title)
   res.author = decode(handle_author(ast, res.title))
   res.entries = {}
   res.type = "json"
   if ast.items then
      for _, v in ipairs(ut.listify(ast.items)) do
         res.entries[#res.entries + 1] = handle_entry(v, res.author, res.title, res.link, url)
      end
   end
   return res
end
