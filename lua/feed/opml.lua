local M = {}
local ut = require("feed.utils")
local xml = require("feed.parser.xml")

local format, concat, insert = string.format, table.concat, table.insert
local spairs, ipairs = vim.spairs, ipairs

---@param src string
---@return feed.opml?
function M.import(src)
   local ast = xml.parse(src, "")
   local ret = {}

   local function handle(node, tags)
      local outline = ut.listify(node.outline)
      for _, v in ipairs(outline) do
         if tags then
            if not v.tags then
               v.tags = {}
            end
            for _, t in ipairs(tags) do
               insert(v.tags, t)
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
            insert(v.tags, v.text)
            handle(v, v.tags)
         end
      end
   end
   if ast then
      handle(ast.opml.body)
      return ret
   end
end

---@param t table
---@return string
local function format_outline(t)
   local acc = vim.iter(t):fold({}, function(acc, k, v)
      insert(acc, format('%s="%s"', k, v))
      return acc
   end)
   return format("<outline %s/>", concat(acc, " "))
end

---@param feeds feed.opml
---@return string
function M.export(feeds)
   local root = [[<?xml version="1.0" encoding="UTF-8"?>
<opml version="1.0"><head><title>%s</title></head><body>
%s
</body></opml>]]
   local acc = vim.iter(spairs(feeds)):fold({}, function(acc, xmlUrl, feed)
      if type(feed) == "table" then
         acc[#acc + 1] = format_outline({
            text = feed.description or feed.title,
            title = feed.title,
            htmlUrl = feed.htmlUrl,
            xmlUrl = require("feed.integrations.rsshub")(xmlUrl, require("feed.config").rsshub.export),
            type = "rss",
         })
      end
      return acc
   end)
   return format(root, "feed.nvim export", concat(acc, "\n"))
end

return M
