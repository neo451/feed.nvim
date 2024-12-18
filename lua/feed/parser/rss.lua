local date = require("feed.parser.date")
local ut = require("feed.utils")
local p_ut = require("feed.parser.utils")
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
---@param base string
---@return string?
local function handle_link(node, base) -- TODO: base and rebase modified for rss?
   if not (node or node.link or node.enclosure) then
      return base
   end
   if node.enclosure then
      return node.enclosure.url
   end
   if not vim.islist(node.link) then
      return ut.url_resolve(base, sensible(node.link, "href"))
   end
   if type(node.link[1]) == "string" then
      return ut.url_resolve(base, node.link[1])
   end
   for _, v in ipairs(node.link) do
      if v.rel == "alternate" then
         return ut.url_resolve(base, v.href)
      elseif v.rel == "self" then
         return ut.url_resolve(base, v.href)
      end
   end
   return base
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

local function handle_entry(entry, feed_url, feed_name, feed_author, url_id)
   local res = {}
   res.link = handle_link(entry, feed_url)
   res.content = handle_content(entry, "empty entry")
   res.title = decode(handle_entry_title(entry, "no title"))
   res.time = handle_date(entry)
   res.author = decode(handle_author(entry, feed_author or feed_name))
   res.feed = url_id
   return res
end

local function handle_rss(ast, url_id)
   local res = {}
   res.version = handle_version(ast)
   local channel = ast.rss and ast.rss.channel or ast["rdf:RDF"].channel
   res.link = handle_link(channel, url_id)
   res.title = decode(handle_title(channel, res.link))
   local feed_author = decode(handle_author(channel, res.title))
   res.desc = decode(handle_description(channel, res.title))
   res.entries = {}
   res.type = "rss"
   if channel.item then
      for _, v in ipairs(ut.listify(channel.item)) do
         res.entries[#res.entries + 1] = handle_entry(v, res.link, res.title, feed_author, url_id)
      end
   end
   return res
end

return handle_rss
