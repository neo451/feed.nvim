local date = require "feed.parser.date"
local sha = vim.fn.sha256
local ut = require "feed.utils"
local strings = require "plenary.strings"

local function handle_title(entry)
   if not entry.title then
      return strings.truncate(entry.content_html, 20)
   end
   return entry.title
end

local function handle_entry(entry, author, feed_name)
   local res = {}
   res.link = entry.url
   res.id = sha(entry.url)
   res.title = handle_title(entry)
   res.time = date.new_from.json(entry.date_published)
   res.author = author
   res.content = entry.content_html or ""
   res.feed = feed_name
   return res
end

---@param thing table | string
---@param field string | integer
---@return string
local function sensible(thing, field, fallback)
   if not thing then
      return fallback
   end
   if type(thing) == "table" then
      --- TODO: handle if list
      if vim.tbl_isempty(thing) then
         return fallback
      elseif type(thing[field]) == "string" then
         return thing[field]
      else
         return fallback
      end
   elseif type(thing) == "string" then
      if thing == "" then
         return fallback
      else
         return thing
      end
   else
      return fallback
   end
end

local function handle_author(ast, feed_name)
   return sensible(ast.author, "name", feed_name)
end

return function(ast, _) -- no link resolve for now only do html link resolve later
   local res = {}
   res.version = "json1"
   res.title = ast.title
   res.link = ast.home_page_url or ast.feed_url
   res.desc = ast.description or res.title
   res.author = handle_author(ast, res.title)
   res.entries = {}
   res.type = "json"
   if ast.items then
      for _, v in ipairs(ut.listify(ast.items)) do
         res.entries[#res.entries + 1] = handle_entry(v, res.author, res.title)
      end
   end
   return res
end
