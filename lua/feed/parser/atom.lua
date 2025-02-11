local date = require("feed.parser.date")
local ut = require("feed.utils")
local p_ut = require("feed.parser.utils")
local sensible = p_ut.sensible
local decode = require("feed.lib.entities").decode

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
      for _, v in ipairs(vim._ensure_list(ast.link)) do
         if v.rel == "alternate" then
            return ut.url_resolve(base, v.href)
            -- elseif v.rel == "self" then
            --    return ut.url_resolve(base, v.href)
         end
      end
      return base
      -- return ut.url_resolve(base, ast.link[1].href) -- just in case..?
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

local function handle_content(entry, fallback)
   local content = entry["content"] or entry["summary"]
   if not content then
      return fallback
   end
   return content[1]
end

local function handle_date(entry)
   local time = sensible(entry["published"] or entry["updated"], 1)
   return date.parse(time, "atom")
end

local function handle_feed_title(ast, url)
   return sensible(ast.title, 1, url)
end

---@return string?
local function handle_author(entry, fallback)
   return sensible(entry.author, "name", fallback)
end

local function handle_description(feed)
   if feed.subtitle then
      return sensible(feed.subtitle, 1)
   else
      return handle_feed_title(feed)
   end
end

local function handle_entry(entry, base, feed_name, url_id)
   local res = {}
   local entry_base = ut.url_rebase(entry, base)
   res.link = handle_link(entry, entry_base)
   res.time = handle_date(entry)
   res.title = decode(handle_title(entry, "no title"))
   res.author = decode(handle_author(entry, feed_name))
   res.content = handle_content(entry, "")
   res.feed = url_id
   return res
end

local function handle_atom(ast, url)
   local res = {}
   local feed = ast.feed
   res.version = handle_version(ast)
   local root_base = ut.url_rebase(feed, url)
   res.link = handle_link(feed, root_base)
   res.desc = decode(handle_description(feed))
   res.title = decode(handle_feed_title(feed, res.link))
   res.entries = {}
   res.type = "atom"
   if feed.entry then
      for _, v in ipairs(vim._ensure_list(feed.entry)) do
         res.entries[#res.entries + 1] = handle_entry(v, root_base, res.title, url)
      end
   end
   return res
end

return handle_atom
