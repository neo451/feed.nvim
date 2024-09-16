local treedoc = require "treedoc"
local date = require "feed.date"
local sha1 = require "feed.sha1"
local ut = require "feed.utils"

---check if json
---@param str string
---@return boolean
local function is_json(str)
   local ok = pcall(vim.json.decode, str)
   return ok
end

---@param entry table
---@param feedtype string
---@param title string
---@return feed.entry
local function reify_entry(entry, feedtype, title)
   local res = {}
   if feedtype == "rss" then
      res.link = entry.link
      res.id = sha1(entry.link)
      res.feed = title
      res.title = entry.title
      res.time = date.new_from.rss(entry.pubDate)
      res.content = entry["content:encoded"] or entry.description
      res.author = entry.author or title
   elseif feedtype == "json" then
      res.link = entry.url
      res.id = sha1(entry.url)
      res.feed = title
      res.title = entry.title
      res.time = date.new_from.json(entry.date_published)
      res.author = title
      res.content = entry.content_html
   elseif feedtype == "atom" then -- TODO: read spec!!!
   end
   res.tags = { unread = true }
   return res
end

local function make_sure_list(t)
   if #t == 0 and not vim.islist(t) then
      t = { t }
   end
   return t
end

---walk the ast and retrive usefull info for all three types
---@param ast table
---@return feed.feed
local function reify(ast, feedtype)
   local res = {}
   if feedtype == "rss" then
      res.title = ast.channel.title
      res.link = ast.channel.link
      res.entries = {}
      for i, v in ipairs(make_sure_list(ast.channel.item)) do
         res.entries[i] = reify_entry(v, "rss", res.title)
      end
   elseif feedtype == "json" then
      res.title = ast.title
      res.link = ast.feed_url
      res.entries = {}
      for i, v in ipairs(make_sure_list(ast.items)) do
         res.entries[i] = reify_entry(v, "json", res.title)
      end
   elseif feedtype == "atom" then
      res.title = ast.title
      for _, v in ipairs(ast.link) do
         if v.type and ut.looks_like_url(v.href) then -- HACK: check spec
            res.link = v.href
         end
      end
      for i, v in ipairs(make_sure_list(ast.entry)) do
         res.entries[i] = reify_entry(v, "atom", res.title)
         -- Pr(v)
      end
   end
   return res
end

---@alias feed.feedtype "rss" | "atom" | "json"

---parse feed fetch from source
---@param src string
---@param opts? {type : feed.feedtype, reify : boolean }
---@return table
---@return feed.feedtype
local function parse(src, opts)
   local ast, feedtype
   opts = opts or {}
   if opts.type == "json" or is_json(src) then
      ast, feedtype = vim.json.decode(src), "json"
   else
      local body = treedoc.parse(src, { language = "xml" })[1]
      if opts.type == "rss" or body.rss then
         ast, feedtype = body.rss, "rss"
      elseif opts.type == "atom" or body.feed then
         ast, feedtype = body.feed, "atom"
      else
         error "failed to parse the unknown feedtype"
      end
   end
   if opts.reify then
      return reify(ast, feedtype), feedtype
   end
   return ast, feedtype
end

return {
   parse = parse,
   reify = reify,
}
