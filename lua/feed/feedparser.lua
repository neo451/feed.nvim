local xml = require "feed.xml"
local date = require "feed.date"
local sha1 = require "sha1"
local ut = require "feed.utils"
local format = require "feed.format"

---check if json
---@param str string
---@return boolean
local function is_json(str)
   local ok = pcall(vim.json.decode, str)
   return ok
end

local function handle_rss_title(ast)
   if type(ast.channel.title) == "table" and vim.tbl_isempty(ast.channel.title) then
      return ast.channel.link
   end
   return ast.channel.title
end

local function handle_atom_link(ast, base)
   if not vim.islist(ast.link) then
      return ut.url_resolve(base, ast.link.href)
   end
   for _, v in ipairs(ast.link) do
      if v.rel == "alternate" then
         return ut.url_resolve(base, v.href)
      end
   end
   return ut.url_resolve(base, ast.link[1].href) -- just in case..?
end

local function handle_atom_title(title)
   if type(title) == "table" then
      return title[1]
   elseif type(title) == "string" then
      return title
   end
end

local function handle_atom_content(content)
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

---@param entry table
---@param feedtype string
---@param title string
---@param base? string # base url
---@return feed.entry
local function reify_entry(entry, feedtype, title, base)
   local res = {}
   if feedtype == "rss" then
      -- TODO: Unlike Atom, RSS feeds themselves also don’t have identifiers. Due to RSS guids never actually being GUIDs, in order to uniquely identify feed entries in Elfeed I have to use a tuple of the feed URL and whatever identifier I can gather from the entry itself. It’s a lot messier than it should be.
      res.link = entry.link
      res.id = sha1(entry.link)
      res.feed = title
      res.title = entry.title
      local ok, time = pcall(function()
         return date.new_from.rss(entry.pubDate):absolute()
      end)
      if ok then
         res.time = time
      end
      res.content = handle_rss_content(entry)
      res.author = entry.author or title
   elseif feedtype == "json" then
      res.link = entry.url
      res.id = sha1(entry.url)
      res.feed = title
      res.title = entry.title
      res.time = date.new_from.json(entry.date_published):absolute()
      res.author = title
      res.content = entry.content_html
   elseif feedtype == "atom" then
      res.link = handle_atom_link(entry, base)
      res.id = sha1(res.link)
      res.title = handle_atom_title(entry.title)
      res.feed = title
      res.time = date.new_from.atom(entry.published):absolute()
      res.author = title
      res.content = handle_atom_content(entry.content)
   end
   res.tags = { unread = true }
   local ok, md = pcall(format.entry, res)
   if ok then
      res.content = md
   else
      print(md)
   end
   return res
end

---walk the ast and retrive usefull info for all three types
---@param ast table
---@return feed.feed
local function reify(ast, feedtype, base_uri)
   local res = {}
   if feedtype == "rss" then
      res.title = handle_rss_title(ast)
      res.link = ast.channel.link
      res.desc = ast.channel.subtitle or res.title
      res.entries = {}
      for i, v in ipairs(ut.listify(ast.channel.item)) do
         res.entries[i] = reify_entry(v, "rss", res.title)
      end
   elseif feedtype == "json" then
      res.title = ast.title
      res.link = ast.home_page_url or ast.feed_url
      res.desc = ast.description or res.title
      res.entries = {}
      for i, v in ipairs(ut.listify(ast.items)) do
         res.entries[i] = reify_entry(v, "json", res.title)
      end
   elseif feedtype == "atom" then
      local root_base = ut.url_rebase(ast, base_uri)
      res.title = ast.title[1]
      res.desc = res.title -- TODO:
      res.link = handle_atom_link(ast, root_base)
      res.entries = {}
      for i, v in ipairs(ut.listify(ast.entry)) do
         res.entries[i] = reify_entry(v, "atom", res.title, root_base)
      end
   end
   return res
end

---@alias feed.feedtype "rss" | "atom" | "json"

---parse feed fetch from source
---@param src string
---@param opts? {type : feed.feedtype, reify : boolean }
---@return table | feed.feed
---@return feed.feedtype
local function parse(src, opts, base_uri)
   local ast, feedtype
   opts = opts or { reify = true }
   if opts.type == "json" or is_json(src) then
      ast, feedtype = vim.json.decode(src), "json"
   else
      local body = xml.parse(src)
      if opts.type == "rss" or body.rss then
         ast, feedtype = body.rss, "rss"
      elseif opts.type == "atom" or body.feed then
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

return {
   parse = parse,
   reify = reify,
}
