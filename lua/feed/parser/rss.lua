local date = require "feed.parser.date"
local ut = require "feed.utils"
local p_ut = require "feed.parser.utils"
local sensible = p_ut.sensible
local decode = require("feed.lib.entities").decode

local function handle_version(ast)
   local version
   if ast["rdf:RDF"] then
      if ast["rdf:RDF"].xmlns == "http://purl.org/rss/1.0/" then
         version = "rss10"
      elseif ast["rdf:RDF"].xmlns == "http://my.netscape.com/rdf/simple/0.9/" then
         version = "rss090"
      end
   elseif ast.rss.version == "2.0" then
      version = "rss20"
   elseif ast.rss.version == "0.91" then
      version = "rss091" -- Userland and Netscape
   elseif ast.rss.version == "0.92" then
      version = "rss092"
   else
      version = "rss"
   end
   return version
end

---@param node table
---@return string?
local function handle_title(node, fallback)
   local title = sensible(node.title, 1, fallback)
   return vim.trim(title)
end

---@param node table
---@param feed_url string
---@return string?
local function handle_link(node, feed_url) -- TODO: base and rebase modified for rss?
   if not node or not node.link then
      return feed_url
   end
   if node.enclosure then
      return node.enclosure.url
   end
   if not vim.islist(node.link) then
      return node.link.href
      -- return ut.url_resolve(base, entry.link.href)
   end
   if type(node.link[1]) == "string" then
      return node.link[1]
   end
   for _, v in ipairs(node.link) do
      if v.rel == "alternate" then
         return v.href
         -- return ut.url_resolve(base, v.href)
      elseif v.rel == "self" then
         return v.href
         -- return ut.url_resolve(base, v.href)
      end
   end
   return feed_url
end

local function handle_author(node, fallback)
   return sensible(node["author"] or node["dc:creator"] or node["itunes:author"], 1, fallback)
end

local function handle_date(entry)
   local time = sensible(entry.pubDate or entry["dc:date"], 1)
   return date.parse(time, "rss")
end

local function handle_content(entry, fallback)
   -- TODO: type of content not relevant?
   local content = sensible(entry["content:encoded"] or entry.description, 1)
   if content then
      return content
   else
      return fallback
   end
end

local function handle_entry_title(entry, fallback)
   return sensible(entry.title, 1, fallback)
end

local function handle_description(channel, fallback)
   return sensible(channel.description or channel["dc:description"] or channel["itunes:subtitle"], 1, fallback)
end


local function handle_entry(entry, feed_url, feed_name, feed_author)
   local res = {}
   res.link = handle_link(entry, feed_url)
   res.content = handle_content(entry, "empty entry")
   res.title = decode(handle_entry_title(entry, "no title"))
   res.time = handle_date(entry)
   res.author = decode(handle_author(entry, feed_author or feed_name))
   res.feed = feed_name
   return res
end

local function handle_rss(ast, feed_url)
   local res = {}
   res.version = handle_version(ast)
   local channel = ast.rss and ast.rss.channel or ast["rdf:RDF"].channel
   local root_base = ut.url_rebase(channel, feed_url)
   res.link = handle_link(channel, feed_url) -- TODO: url resolver
   res.title = decode(handle_title(channel, res.link))
   local feed_author = decode(handle_author(channel, res.title))
   res.desc = decode(handle_description(channel, res.title))
   res.entries = {}
   res.type = "rss"
   if channel.item then
      for _, v in ipairs(ut.listify(channel.item)) do
         res.entries[#res.entries + 1] = handle_entry(v, root_base, res.title, feed_author) -- TODO: feed_url should be the entry's feed attr, but resolove should not prioritize feed_url
      end
   end
   return res
end

return handle_rss
