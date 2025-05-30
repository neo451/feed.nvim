local date = require("feed.parser.date")
local ut = require("feed.utils")
local clean = ut.clean
local resolve = require("feed.parser.html").resolve

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
---@param base string
---@return string?
local function handle_link(node, base) -- TODO: base and rebase modified for rss?
   if not node then
      return base
   end
   if node.enclosure then
      return node.enclosure.url
   end
   if node.link then
      if node.link and node.link["href"] then -- TODO:???
         return ut.url_resolve(base, node.link["href"])
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
   local time_node = entry["pubDate"] or entry["dc:date"] or entry["date"]
   return date.parse(time_node and time_node[1], "rss")
end

local function handle_content(entry, url)
   local content_node = entry["content:encoded"]
      or entry["content"]
      or entry["itunes:summary"]
      or entry["itunes:subtitle"]
      or entry["description"]
   if content_node and content_node[1] then
      local content = clean(content_node[1])
      return resolve(content, url)
   else
      return ""
   end
end

---@param node table
---@return string?
local function handle_title(node, fallback)
   local title_node = node.title
   if title_node then
      return clean(title_node[1] or title_node)
   else
      return fallback
   end
end

local function handle_description(channel)
   local desc_node = channel["description"] or channel["dc:description"] or channel["itunes:subtitle"]
   if desc_node then
      return clean(desc_node[1] or desc_node)
   end
end

local function handle_entry(entry, feed, url)
   local res = {}
   res.link = handle_link(entry, feed.link)
   res.content = handle_content(entry, feed.link)
   res.title = handle_title(entry, "no title")
   res.time = handle_date(entry)
   res.author = handle_author(entry) or feed.author
   res.feed = url
   return res
end

return function(ast, url)
   local res = {}
   res.version = handle_version(ast)
   local channel = ast.rss and ast.rss.channel or ast["rdf:RDF"].channel
   res.link = handle_link(channel, url)
   res.title = handle_title(channel, res.link)
   res.author = handle_author(channel)
   res.desc = handle_description(channel)
   res.entries = {}
   local item_node
   if res.version == "rss10" or res.version == "rss090" then
      item_node = ast["rdf:RDF"].item
   elseif channel.item then
      item_node = channel.item
   end
   for _, v in ipairs(ut.listify(item_node or {})) do
      res.entries[#res.entries + 1] = handle_entry(v, res, url)
   end
   return res
end
