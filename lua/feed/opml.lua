local opml = {}
local ut = require "feed.utils"

local function format_outline(t)
   return ([[<outline text="%s" title="%s" type="%s" xmlUrl="%s" htmlUrl="%s"/>]]):format(t.title, t.title, t.type, t.xmlUrl, t.htmlUrl)
end

---@param title string
---@param contents string
local function format_root(title, contents)
   local str = ([[<?xml version="1.0" encoding="UTF-8"?>
<opml version="1.0"><head><title>%s</title></head><body>
%s
</body></opml>]]):format(title, contents)
   return str
end

local treedoc = require "treedoc"

local mt = { __type = "opml" }
mt.__index = mt

mt.__tostring = function(self)
   return ("<OPML>name: %s, size: %d"):format(self.title, #self.outline)
end

---@param src string
---@return feed.opml
function opml.import(src)
   local ast = treedoc.parse(src, { language = "xml" })[1]
   local outline = ast.opml.body.outline
   local title = ast.opml.head.title
   outline = ut.listify(outline)
   local id, names = {}, {}
   for i, v in ipairs(outline) do
      id[v.xmlUrl] = i
      names[v.title] = i
   end
   return setmetatable({
      outline = outline,
      title = title,
      id = id,
      names = names,
   }, mt)
end

---@param topath string?
---@return string?
function mt:export(topath)
   local entries = self.outline
   local buf = {}
   for _, v in ipairs(entries) do
      buf[#buf + 1] = format_outline(v)
   end
   local str = format_root(self.title, table.concat(buf, "\n"))
   if topath then
      local file = io.open(topath, "w")
      if file then
         file:write(str)
         file:close()
      end
   end
end

---@param name string
function mt:lookup(name)
   local idx = self.names[name]
   if idx then
      return self.outline[idx]
   end
end

---@param t table
function mt:append(t)
   if self.id[t.xmlUrl] then
      local idx = self.id[t.xmlUrl]
      self.outline[idx] = { text = t.title, title = t.title, type = t.type or "rss", htmlUrl = t.htmlUrl, xmlUrl = t.xmlUrl }
      return
   end
   self.outline[#self.outline + 1] = { text = t.title, title = t.title, type = t.type or "rss", htmlUrl = t.htmlUrl, xmlUrl = t.xmlUrl }
   self.id[t.xmlUrl] = #self.outline
   self.names[t.title] = #self.outline
end

return opml
