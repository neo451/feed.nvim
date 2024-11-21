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
   return format(outline_format, t.text or t.title, t.title, t.type or "rss", xmlUrl, t.htmlUrl)
end

---@param src string
---@return feed.opml?
function M.import(src)
   local ok, ast = pcall(xml.parse, src, "")
   local ret = {}

   local function handle(node, tags)
      local outline = ut.listify(node.outline)
      for _, v in ipairs(outline) do
         if tags then
            if not v.tag then
               v.tag = {}
            end
            for _, t in ipairs(tags) do
               table.insert(v.tag, t)
            end
         end
         if v.xmlUrl then
            local url = v.xmlUrl
            if v.text == v.title then
               v.text = nil -- if same then use fetched info later
            end
            v.type = nil
            v.xmlUrl = nil
            ret[url] = v
         elseif v.outline then
            handle(v, { v.text, unpack(v.tag or {}) })
         end
      end
   end
   if ok and ast then
      handle(ast.opml.body)
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
