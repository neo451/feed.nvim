local date = require "feed.parser.date"
local sha = vim.fn.sha256
local ut = require "feed.utils"
local strings = require "plenary.strings"
local p_ut = require "feed.parser.utils"
local sensible = p_ut.sensible

local function handle_version(ast)
   if ast.feed.version == "1.0" or not ast.feed.version then
      return "atom10"
   elseif ast.feed.version == "0.3" then
      return "atom03"
   end
end

---@return string?
local function handle_link(ast, base)
   local T = type(ast.link)
   base = ut.url_rebase(ast, base)
   if T == "table" then
      if not vim.islist(ast.link) then
         return ut.url_resolve(base, ast.link.href)
      end
      for _, v in ipairs(ast.link) do
         if v.rel == "alternate" then
            return ut.url_resolve(base, v.href)
         elseif v.rel == "self" then
            return ut.url_resolve(base, v.href)
         end
      end
      return ut.url_resolve(base, ast.link[1].href) -- just in case..?
   elseif T == "string" then
      return ast.link
   end
end

-- TODO: fallback to content:sub()
local function handle_title(entry)
   local function handle(v)
      if type(v) == "table" then
         return v[1] or ""
      elseif type(v) == "string" then
         return v
      end
   end
   if vim.islist(entry.title) then
      for _, v in ipairs(entry.title) do
         if v.type == "html" then
            return handle(v) -- TODO: there can be same tag atom tags together
         end
      end
      return handle(entry.title[1])
   end
   return handle(entry.title)
end

local function handle_content(entry)
   local content = entry["content"] or entry["summary"]
   if not content then
      return "this feed seems to be empty..."
   end
   -- TODO: use urlview to get relative links and resolve
   if content.type == "html" then
      return content[1]
   else
      -- TODO: treedoc power!
      return "xhtml not supported now"
   end
end

local function handle_date(entry)
   local time = sensible(entry["published"] or entry["updated"], 1)
   return date.new_from.atom(time)
end

local function handle_feed_title(ast, url)
   return sensible(ast.title, 1, url)
end

---@return string?
local function handle_author(entry, fallback)
   return sensible(entry.author, "name", fallback)
end

local function handle_description(feed)
   if feed.subtitle then
      return sensible(feed.subtitle, 1)
   else
      return handle_feed_title(feed)
   end
end

local function handle_entry(entry, base, feed_name)
   local res = {}
   local entry_base = ut.url_rebase(entry, base)
   res.link = handle_link(entry, entry_base)
   res.id = sha(res.link)
   res.title = handle_title(entry)
   res.time = handle_date(entry)
   res.author = handle_author(entry, feed_name)
   res.content = handle_content(entry)
   res.feed = feed_name
   return res
end

local function handle_atom(ast, feed_url)
   local res = {}
   local feed = ast.feed
   res.version = handle_version(ast)
   local root_base = ut.url_rebase(feed, feed_url)
   res.desc = handle_description(feed)
   res.link = handle_link(feed, root_base)
   res.title = handle_feed_title(feed, res.link)
   res.entries = {}
   res.type = "atom"
   if feed.entry then
      for _, v in ipairs(ut.listify(feed.entry)) do
         res.entries[#res.entries + 1] = handle_entry(v, root_base, res.title)
      end
   end
   return res
end

return handle_atom