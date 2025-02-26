local date = require("feed.parser.date")
local resolve = require("feed.parser.html").resolve
local ut = require("feed.utils")
local clean = ut.clean

local function handle_version(node)
   if node.version == "1.0" or not node.version then
      return "atom10"
   elseif node.version == "0.3" then
      return "atom03"
   end
end

---@return string?
local function handle_link(node, base)
   local T = type(node.link)
   base = ut.url_rebase(node, base)
   if T == "table" then
      local list = ut.listify(node.link)
      for _, v in ipairs(list) do
         if v.rel == "alternate" then
            if not ut.looks_like_url(v.href) then
               return ut.url_resolve(base, v.href)
            else
               return v.href
            end
         end
      end
      return ut.url_resolve(list[1].href)
   elseif T == "string" then
      return node.link
   end
end

local function handle_title(entry, fallback)
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
   return handle(entry.title or fallback)
end

local function handle_feed_title(ast, url)
   if not ast.title then
      return url
   end
   return clean(ast.title[1])
end

local function handle_content(entry, fallback, url)
   local content_node = entry["content"] or entry["summary"]
   if not content_node then
      return fallback
   end
   local content = clean(content_node[1])
   return resolve(content, url)
end

local function handle_date(entry)
   local time_node = entry["published"] or entry["updated"]
   return date.parse(time_node and time_node[1], "atom")
end

---@return string?
local function handle_author(node, fallback)
   local author_node = node.author or node["itunes:author"]
   if author_node then
      local name = clean(author_node.name[1])
      if name then
         return name
      end
   else
      return fallback
   end
end

local function handle_description(feed)
   if not feed.subtitle then
      return
   end
   return clean(feed.subtitle[1])
end

---@param entry table
---@param feed feed.feed
---@param base string
---@return table
local handle_entry = function(entry, feed, base, url)
   local res = {}
   local entry_base = ut.url_rebase(entry, base)
   res.link = handle_link(entry, entry_base)
   res.time = handle_date(entry)
   res.title = handle_title(entry, "no title")
   res.author = handle_author(entry)
   res.content = handle_content(entry, "", feed.link)
   res.feed = url
   return res
end

local function handle_atom(ast, url)
   local res = {}
   local feed = ast.feed
   local base = ut.url_rebase(feed, url)
   res.version = handle_version(feed)
   res.link = handle_link(feed, base)
   res.desc = handle_description(feed)
   res.title = handle_feed_title(feed, res.link)
   res.author = handle_author(feed)
   res.entries = {}
   if feed.entry then
      for _, v in ipairs(ut.listify(feed.entry)) do
         res.entries[#res.entries + 1] = handle_entry(v, res, base, url)
      end
   end
   return res
end

return handle_atom
