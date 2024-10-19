local M = {}
local ut = require "feed.utils"
local xml = require "feed.xml"

local format = string.format
local concat = table.concat

local outline_format = [[<outline text="%s" title="%s" type="%s" xmlUrl="%s" htmlUrl="%s"/>]]
local root_format = [[<?xml version="1.0" encoding="UTF-8"?>
<opml version="1.0"><head><title>%s</title></head><body>
%s
</body></opml>]]

---@param t table
---@return string
local function format_outline(t)
   return format(outline_format, t.title, t.title, t.type, t.xmlUrl, t.htmlUrl)
end

---@param title string
---@param contents string
local function format_root(title, contents)
   return format(root_format, title, contents)
end

local mt = { __class = "feed.opml" }
mt.__index = mt

mt.__tostring = function(self)
   return ("<OPML>name: %s, size: %d"):format(self.title, #self.outline)
end

---@param src string
---@return feed.opml
function M.import(src)
   local ast = xml.parse(src)
   local outline = ast.opml.body.outline
   local title = ast.opml.head.title
   outline = ut.listify(outline)
   local id, names = {}, {}
   for i, v in ipairs(outline) do
      if v.xmlUrl then
         id[v.xmlUrl] = i
         if v.title then
            names[v.title] = i
         end
      else
         ut.notify("opml", {
            level = "INFO",
            msg = ("failed to import feed %s"):format(v.title or v.text or v.htmlUrl),
         })
         table.remove(outline, i)
      end
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
   local str = format_root(self.title, concat(buf, "\n"))
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

---@param v table
function mt:append(v)
   if self.id[v.xmlUrl] then
      local idx = self.id[v.xmlUrl]
      self.outline[idx] = { text = v.title, title = v.title, type = v.type or "rss", htmlUrl = v.htmlUrl, xmlUrl = v.xmlUrl }
      return
   end
   if not v.xmlUrl then
      ut.notify("opml", {
         level = "INFO",
         msg = ("failed to import feed %s"):format(v.title or v.text or v.htmlUrl),
      })
      return
   end
   self.outline[#self.outline + 1] = { text = v.title, title = v.title, type = v.type or "rss", htmlUrl = v.htmlUrl, xmlUrl = v.xmlUrl }
   self.id[v.xmlUrl] = #self.outline
   self.names[v.title] = #self.outline
end

return M
