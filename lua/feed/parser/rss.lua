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

local function handle_author(node)
   local author_node = node["itunes:author"] or node["author"] or node["dc:creator"] or node["dc:author"]
   if author_node then
      return clean(author_node[1] or author_node.name)
   end
end

local function handle_date(entry)
   local time = sensible(entry.pubDate or entry["dc:date"], 1)
   return date.parse(time, "rss")
end

local function handle_content(entry, fallback, url)
   local content = sensible(entry["content:encoded"] or entry["description"], 1)
   if content then
      return resolve(clean(content), url)
   else
      return fallback
   end
end

local function handle_entry_title(entry, fallback)
   return sensible(entry.title, 1, fallback)
end

local function handle_description(channel, fallback)
   return clean(sensible(channel.description or channel["dc:description"] or channel["itunes:subtitle"], 1, fallback))
end

local function handle_entry(entry, feed, url)
   local res = {}
   res.link = handle_link(entry, feed.link)
   res.content = handle_content(entry, "", feed.link)
   res.title = decode(handle_entry_title(entry, "no title"))
   res.time = handle_date(entry)
   res.author = handle_author(entry) or feed.author
   res.feed = url
   return res
end

local function handle_rss(ast, url)
   local res = {}
   res.version = handle_version(ast)
   local channel = ast.rss and ast.rss.channel or ast["rdf:RDF"].channel
   res.link = handle_link(channel, url)
   res.title = decode(handle_title(channel, res.link))
   res.author = handle_author(channel)
   res.desc = decode(handle_description(channel, res.title))
   res.entries = {}
   res.type = "rss"
   if channel.item then
      for _, v in ipairs(ut.listify(channel.item)) do
         res.entries[#res.entries + 1] = handle_entry(v, res, url)
      end
   end
   return res
end

return handle_rss
