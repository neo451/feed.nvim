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
local Path = require "plenary.path"

local mt = { __type = "opml" }
mt.__index = mt

mt.__tostring = function(self)
   return ("<OPML>name: %s, size: %d"):format(self.title, #self.outline)
end

---@param frompath string
---@return feed.opml
function opml.import(frompath)
   local path = Path:new(Path:new(frompath):expand())
   local src = path:read()
   local ast = treedoc.parse(src, { language = "xml" })[1]
   local outline = ast.opml.body.outline
   local title = ast.opml.head.title
   outline = ut.listify(outline)
   local id = {}
   for _, v in ipairs(outline) do
      id[v.xmlUrl] = true
   end
   return setmetatable({
      outline = outline,
      title = title,
      id = id,
   }, mt)
end

---@param str string
---@return feed.opml
function opml.import_s(str)
   local ast = treedoc.parse(str, { language = "xml" })[1]
   local outline = ast.opml.body.outline
   local title = ast.opml.head.title
   outline = ut.listify(outline)
   local id = {}
   for _, v in ipairs(outline) do
      id[v.xmlUrl] = true
   end
   return setmetatable({
      outline = outline,
      title = title,
      id = id,
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
      local path = Path:new(Path:new(topath):expand())
      path:write(str, "w")
   else
      return str
   end
end

---@param t table
function mt:append(t)
   if self.id[t.xmlUrl] then
      return
   end
   self.id[t.xmlUrl] = true
   self.outline[#self.outline + 1] = { text = t.title, title = t.title, type = t.type or "rss", htmlUrl = t.htmlUrl, xmlUrl = t.xmlUrl }
end

return opml
