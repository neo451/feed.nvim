local M = {}
local ut = require "feed.utils"
local xml = require "feed.xml"
local log = require "feed.log"

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
mt.__index = function(self, k)
   if not rawget(self, k) then
      if rawget(mt, k) then
         return rawget(mt, k)
      end
   end
end

---@param src string
---@return feed.opml
function M.import(src)
   local ast = xml.parse(src, "import opml")
   local outline = ast.opml.body.outline
   local ret = {}
   outline = ut.listify(outline)
   local names = {}
   for _, v in ipairs(outline) do
      if v.xmlUrl and v.title then
         ret[v.xmlUrl] = v
         names[v.title] = v.xmlUrl
      else
         log.info(("failed to import feed %s"):format(v.title or v.text or v.htmlUrl))
      end
   end
   ret.names = names
   return setmetatable(ret, mt)
end

---@return feed.opml
function M.new()
   return setmetatable({
      names = {},
   }, mt)
end

---@param topath string?
---@return string?
function mt:export(topath)
   local buf = {}
   for k, v in pairs(self) do
      if k ~= "names" then
         buf[#buf + 1] = format_outline(v)
      end
   end
   local str = format_root("feed.nvim export", concat(buf, "\n"))
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
      return self[idx]
   end
end

---@param v table
function mt:append(v)
   if not v.xmlUrl then
      log.info(("failed to import feed %s"):format(v.title or v.text or v.htmlUrl))
      return
   end
   if self[v.xmlUrl] then
      self[v.xmlUrl] = v
      return
   end
   self[v.xmlUrl] = v
   self.names[v.title] = v.xmlUrl
end

M.mt = mt

return M
