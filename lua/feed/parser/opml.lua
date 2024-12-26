local M = {}
local ut = require "feed.utils"
local xml = require "feed.parser.xml"

local format, concat = string.format, table.concat
local spairs, ipairs = vim.spairs, ipairs

---@param src string
---@return feed.opml?
function M.import(src)
   local ok, ast = pcall(xml.parse, src, "")
   local ret = {}

   local function handle(node, tags)
      local outline = ut.listify(node.outline)
      for _, v in ipairs(outline) do
         if tags then
            if not v.tags then
               v.tags = {}
            end
            for _, t in ipairs(tags) do
               table.insert(v.tags, t)
            end
         end
         if v.xmlUrl then
            ret[v.xmlUrl] = {
               htmlUrl = v.htmlUrl,
               title = v.text or v.title,
               tags = vim.deepcopy(tags),
            }
         elseif v.outline then
            if not v.tags then
               v.tags = {}
            end
            table.insert(v.tags, v.text)
            handle(v, v.tags)
         end
      end
   end
   if ok and ast then
      handle(ast.opml.body)
      return ret
   end
end

---@param t table
---@return string
local function format_outline(t)
   local buf = {}
   for k, v in pairs(t) do
      buf[#buf + 1] = format([[%s="%s"]], k, v)
   end
   return "<outline " .. table.concat(buf, " ") .. "/>"
end

local root_format = [[<?xml version="1.0" encoding="UTF-8"?>
<opml version="1.0"><head><title>%s</title></head><body>
%s
</body></opml>]]

local function rsshub_replace(url)
   local Config = require "feed.config"
   return url:find("rsshub:/") and url:gsub("rsshub:/", Config.rsshub_instance) or url
end

---@param feeds feed.opml
---@return string
function M.export(feeds)
   local buf = {}
   for xmlUrl, v in spairs(feeds) do
      if type(v) == "table" then
         buf[#buf + 1] = format_outline {
            text = v.description or v.title,
            title = v.title,
            htmlUrl = v.htmlUrl,
            xmlUrl = rsshub_replace(xmlUrl),
            type = "rss",
         }
      end
   end
   return format(root_format, "feed.nvim export", concat(buf, "\n"))
end

return M
