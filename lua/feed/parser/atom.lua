local date = require("feed.parser.date")
local ut = require("feed.utils")
local sensible = ut.sensible
local decode = ut.decode
local resolve = require("feed.parser.html").resolve

---@param str string?
---@return string?
local clean = function(str)
   str = decode(str)
   return str and vim.trim(str) or nil
end

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
      local list = ut.listify(ast.link)
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
      return ast.link
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

local function handle_content(entry, fallback, url)
   local content = entry["content"] or entry["summary"]
   if not content then
      return fallback
   end
   return resolve(clean(content[1]), url)
end

local function handle_date(entry)
   local time = sensible(entry["published"] or entry["updated"], 1)
   return date.parse(time, "atom")
end

local function handle_feed_title(ast, url)
   return decode(sensible(ast.title, 1, url))
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
   return decode(vim.trim(sensible(feed.subtitle, 1)))
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
   res.version = handle_version(ast)
   local root_base = ut.url_rebase(feed, url)
   res.link = handle_link(feed, root_base)
   res.desc = handle_description(feed)
   res.title = handle_feed_title(feed, res.link)
   res.author = handle_author(feed)
   res.entries = {}
   res.type = "atom"
   if feed.entry then
      for _, v in ipairs(ut.listify(feed.entry)) do
         res.entries[#res.entries + 1] = handle_entry(v, res, root_base, url)
      end
   end
   return res
end

return handle_atom
