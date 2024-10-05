local treedoc = require "treedoc"
local date = require "feed.date"
local sha1 = require "feed.sha1"
local ut = require "feed.utils"

local function make_sure_list(t)
   if #t == 0 and not vim.islist(t) then
      t = { t }
   end
   return t
end

local entry_validator_mt = {}

local expected_types = {
   title = "string",
   link = "string",
   id = "string",
   feed = "string",
   author = "string",
   content = "string",
   time = "number",
}

local default = {
   title = "<>",
   link = "<>",
   id = "<>",
   feed = "<>",
   author = "<>",
   content = "<>",
   time = 222222,
}

-- function entry_validator_mt:__newindex(k, v)
--    if not (type(v) == expected_types[k]) then
--       print("expected " .. expected_types[k] .. " got: " .. type(v))
--       rawset(self, k, default[k]) -- HACK:
--    end
--    rawset(self, k, v)
-- end

local function V(t)
   return setmetatable(t, entry_validator_mt)
end

local function remove_meta(t)
   local mt = getmetatable(t)
   mt.__index = nil
   return t
end

---check if json
---@param str string
---@return boolean
local function is_json(str)
   local ok = pcall(vim.json.decode, str)
   return ok
end

local function handle_atom_link(entry)
   if not vim.islist(entry.link) then
      return entry.link.href
   end
   -- TODO: read spec for the different link types
   return entry.link[1].href
end

local function handle_atom_content(content)
   if content.type == "html" then
      return content[1]
   else
      -- TODO: treedoc power!
      return "xhtml not supported now"
   end
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
      local ok, time = pcall(function()
         return date.new_from.rss(entry.pubDate):absolute()
      end)
      if ok then
         res.time = time
      end
      res.content = entry["content:encoded"] or entry.description or ""
      res.author = entry.author or title
   elseif feedtype == "json" then
      res.link = entry.url
      res.id = sha1(entry.url)
      res.feed = title
      res.title = entry.title
      res.time = date.new_from.json(entry.date_published):absolute()
      res.author = title
      res.content = entry.content_html
   elseif feedtype == "atom" then -- TODO: read spec!!!
      res.link = handle_atom_link(entry)
      res.id = sha1(res.link)
      res.title = entry.title[1]
      res.feed = title
      res.time = date.new_from.atom(entry.published):absolute()
      res.author = title
      res.content = handle_atom_content(entry.content)
   end
   res.tags = { unread = true }
   return res
end

local function handle_rss_title(ast)
   if type(ast.channel.title) == "table" and vim.tbl_isempty(ast.channel.title) then
      return ast.channel.link
   end
   return ast.channel.title
end

---walk the ast and retrive usefull info for all three types
---@param ast table
---@return feed.feed
local function reify(ast, feedtype)
   local res = {}
   if feedtype == "rss" then
      res.title = handle_rss_title(ast)
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
      res.title = ast.title[1]
      res.entries = {}
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
   opts = opts or { reify = true }
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
