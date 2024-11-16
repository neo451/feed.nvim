local M = {}
local ut = require "feed.utils"
local xml = require "feed.parser.xml"

local format, concat = string.format, table.concat
local spairs, ipairs = vim.spairs, ipairs

local outline_format = [[<outline text="%s" title="%s" type="%s" xmlUrl="%s" htmlUrl="%s"/>]]
local root_format = [[<?xml version="1.0" encoding="UTF-8"?>
<opml version="1.0"><head><title>%s</title></head><body>
%s
</body></opml>]]

---@param t table
---@return string
local function format_outline(t, xmlUrl)
   return format(outline_format, t.text, t.title, t.type, xmlUrl, t.htmlUrl)
end

---@param src string
---@return feed.opml?
function M.import(src)
   local ast = xml.parse(src, "")
   if ast then
      local outline = ast.opml.body.outline
      local ret = {}
      outline = ut.listify(outline)
      for _, v in ipairs(outline) do
         if v.xmlUrl then
            local url = v.xmlUrl
            v.xmlUrl = nil
            ret[url] = v
         end
      end
      return ret
   end
end

---@param feeds feed.opml
---@return string
function M.export(feeds)
   local buf = {}
   for xmlUrl, v in spairs(feeds) do
      buf[#buf + 1] = format_outline(v, xmlUrl)
   end
   return format(root_format, "feed.nvim export", concat(buf, "\n"))
end

return M
