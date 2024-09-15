local opml = {}

local function outline(t)
   -- TODO: option to validate type using the data fetched
   return ([[<outline text="%s" title="%s" type="%s" xmlUrl="%s" htmlUrl="%s"/>]]):format(t.htmlUrl, t.title, t.title, t.type, t.xmlUrl)
end

---@param title string
---@param contents string
local function root(title, contents)
   local str = ([[<?xml version="1.0" encoding="UTF-8"?>
<opml version="1.0"><head><title>%s</title></head><body>
%s
</body></opml>]]):format(title, contents)
   return str
end

local treedoc = require "treedoc"

---@param src string
function opml.import(src)
   local ast = treedoc.parse(src, { language = "xml" })[1]
   return ast
end

local Path = require "plenary.path"

---@param ast table
function opml.export(ast, path)
   local entries = ast.opml.body.outline
   local buf = {}
   for _, v in ipairs(entries) do
      buf[#buf + 1] = outline(v)
   end
   local str = root(ast.opml.head.title, table.concat(buf, "\n"))
   if path then
      path = Path:new(path)
      path:write(str, "w")
   else
      return str
   end
end

return opml
