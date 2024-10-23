local xml = require "feed.xml"
local date = require "feed.date"
local ut = require "feed.utils"
local format = require "feed.format"
local sha = vim.fn.sha256

-- TODO: handle enlosures

---check if json
---@param str string
---@return boolean
local function is_json(str)
   local ok = pcall(vim.json.decode, str)
   return ok
end

---Notes:
---1. a feed has: a title, a text desc (optional), and entries (optional)
---2. a entry has: a link, feed is always known, and all others are optional (author, time, content)
---3. fallbacks:
---  - author -> feed
---  - time -> os.time()
---  - content -> ""

local function handle_rss_title(ast)
   if type(ast.title) == "table" then
      if vim.tbl_isempty(ast.title) then
         return ast.link
      end
   end
   return ast.title
end

---@return string?
local function handle_atom_link(ast, base)
   local T = type(ast.link)
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

-- Pr = function(a)
--    print(vim.inspect(a))
-- end

local function handle_atom_title(entry)
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

local function handle_atom_content(entry)
   local content = entry["content"] or entry["summary"]
   if not content then
      return "this feed seems to be empty..."
   end

   if content.type == "html" then
      return content[1]
   else
      -- TODO: treedoc power!
      return "xhtml not supported now"
   end
end

local function handle_rss_content(entry)
   --- rss content is always plain text?
   local function handle_self_closing(t)
      if type(t) == "table" then
         return ""
      end
      return t
   end
   if entry["content:encoded"] then
      return handle_self_closing(entry["content:encoded"])
   elseif entry.description then
      return handle_self_closing(entry.description)
   end
   return ""
end

local function handle_rss_entry_title(entry)
   if type(entry.title) == "table" then
      if vim.tbl_isempty(entry.title) then
         return ""
      else
         print(vim.inspect(entry.title))
      end
   elseif type(entry.title) == "string" then
      return entry.title
   end
end

local function handle_rss_entry_author(entry)
   if type(entry.author) == "table" then
      return entry.author.name -- TODO: read spec
   elseif type(entry.author) == "string" then
      return entry.author
   end
end

local function handle_atom_date(entry)
   local time = entry["published"] or entry["updated"]
   local ok, res = pcall(date.new_from.atom, time)
   if ok and res then
      return res:absolute()
   else
      return os.time()
   end
end

local function handle_rss_date(entry)
   local time = entry.pubDate
   local ok, res = pcall(date.new_from.rss, time)
   if ok and res then
      return res:absolute()
   else
      return os.time()
   end
end

-- TODO: every other handler should have a fallback

---@param link_node any
---@param base any
---@return string?
local function handle_rss_link(entry, base)
   local T = type(entry.link)
   if T == "string" then
      return entry.link
   elseif T == "table" then
      if not vim.islist(entry.link) then
         return entry.link.href
         -- return ut.url_resolve(base, entry.link.href)
      end
      for _, v in ipairs(entry.link) do
         if v.rel == "alternate" then
            return v.href
         -- return ut.url_resolve(base, v.href)
         elseif v.rel == "self" then
            return v.href
            -- return ut.url_resolve(base, v.href)
         end
      end
      return entry.link[1].href -- just in case .. ?
   end
end

local function handle_atom_feed_title(ast)
   if type(ast.title) == "table" then
      -- if vim.tbl_isempty(ast.title) then
      --    return ""
      -- end
      return ast.title[1]
   elseif type(ast.title) == "string" then
      return ast.title
   end
   return ""
end

---@param entry table
---@param feedtype string
---@param feed_name string
---@param base? string # base url
---@return feed.entry?
local function reify_entry(entry, feedtype, feed_name, base)
   local res = {}
   if feedtype == "rss" then
      -- TODO: Unlike Atom, RSS feeds themselves also don’t have identifiers. Due to RSS guids never actually being GUIDs, in order to uniquely identify feed entries in Elfeed I have to use a tuple of the feed URL and whatever identifier I can gather from the entry itself. It’s a lot messier than it should be.
      res.link = handle_rss_link(entry, base)
      if not res.link then
         return
      end
      res.id = sha(res.link)
      res.title = handle_rss_entry_title(entry) -- TODO: proper fallback for each attr
      res.time = handle_rss_date(entry)
      res.content = handle_rss_content(entry)
      res.author = handle_rss_entry_author(entry) or feed_name
   elseif feedtype == "json" then
      res.link = entry.url
      if not res.link then
         return
      end
      res.id = sha(entry.url)
      res.title = entry.title
      res.time = date.new_from.json(entry.date_published):absolute()
      res.author = feed_name
      res.content = entry.content_html
   elseif feedtype == "atom" then
      res.link = handle_atom_link(entry, base)
      if not res.link then
         return
      end
      res.id = sha(res.link)
      res.title = handle_atom_title(entry)
      res.time = handle_atom_date(entry)
      res.author = feed_name
      res.content = handle_atom_content(entry)
   end
   res.tags = { unread = true }
   res.feed = feed_name
   res.content = format.entry(res)
   return res
end

---walk the ast and retrive usefull info for all three types
---@param ast table
---@return feed.feed
local function reify(ast, feedtype, base_uri)
   local res = {}
   if feedtype == "rss" then
      local root_base = ut.url_rebase(ast, base_uri)
      res.title = handle_rss_title(ast)
      res.link = handle_rss_link(ast, base_uri)
      res.desc = ast.subtitle or res.title
      res.entries = {}
      if ast.item then
         for i, v in ipairs(ut.listify(ast.item)) do
            res.entries[i] = reify_entry(v, "rss", res.title, root_base)
         end
      end
   elseif feedtype == "json" then
      res.title = ast.title
      res.link = ast.home_page_url or ast.feed_url
      res.desc = ast.description or res.title
      res.entries = {}
      if ast.items then
         for i, v in ipairs(ut.listify(ast.items)) do
            res.entries[i] = reify_entry(v, "json", res.title)
         end
      end
   elseif feedtype == "atom" then
      local root_base = ut.url_rebase(ast, base_uri)
      res.title = handle_atom_feed_title(ast)
      res.desc = res.title -- TODO:
      res.link = handle_atom_link(ast, root_base)
      res.entries = {}
      if ast.entry then
         for i, v in ipairs(ut.listify(ast.entry)) do
            res.entries[i] = reify_entry(v, "atom", res.title, root_base)
         end
      end
   end
   return res
end

---parse feed fetch from source
---@param src string
---@param base_uri? string
---@param opts? { reify : boolean }
---@return table | feed.feed
---@return "json" | "atom" | "rss"
local function parse(src, base_uri, opts)
   local ast, feedtype
   opts = opts or { reify = true }
   if is_json(src) then
      ast, feedtype = vim.json.decode(src), "json"
   else
      local body = xml.parse(src, base_uri)
      if body.rss then
         -- TODO: get version info here, 2.0, 0.91..
         ast, feedtype = body.rss.channel, "rss"
      elseif body.feed then
         ast, feedtype = body.feed, "atom"
      else
         error "failed to parse the unknown feedtype"
      end
   end
   if opts.reify then
      return reify(ast, feedtype, base_uri), feedtype
   end
   return ast, feedtype
end

return { parse = parse }
