local lpeg = vim.lpeg
local log = require("feed.lib.log")
local ut = require("feed.utils")

local get_text = ut.get_text
local get_root = ut.get_root
local tree_contains = ut.tree_contains

local ENTITIES = {
   ["&lt;"] = "<",
   ["&gt;"] = ">",
   ["&amp;"] = "&",
   ["&apos;"] = "'",
   ["&quot;"] = '"',
}

local H = {}

setmetatable(H, {
   __index = function(t, k)
      if not rawget(t, k) then
         return function() end
      end
   end,
})

---@param node TSNode
---@param src string
---@return table
H.XMLDecl = function(node, src)
   local res = {}
   for child in node:iter_children() do
      if child:type() == "EncName" then
         res.encoding = get_text(child, src)
      end
   end
   return res
end

---@param node TSNode
---@param src string
---@return table
H.prolog = function(node, src)
   local res = {}
   for child in node:iter_children() do
      if child:type() == "XMLDecl" then
         res = H.XMLDecl(child, src)
      end
   end
   return res
end

---@param node TSNode
---@param src string
---@return string
---@return table
H.STag = function(node, src)
   local name = get_text(node:child(1), src)
   local n = node:child_count()
   if n == 3 then
      return name, {}
   end
   local res = {}
   for i = 2, n - 2 do
      local child = node:child(i)
      if child and child:type() == "Attribute" then
         local k, v = get_text(child:child(0), src), get_text(child:child(2), src):gsub('"', "")
         res[k] = v
      end
   end
   return name, res
end

---@param node TSNode
---@param src string
---@return string?
H.CharData = function(node, src)
   local text = get_text(node, src)
   if text:find("%S") then
      return text
   end
end

---@param node TSNode
---@param src string
---@return string
H.CharRef = function(node, src)
   local text = get_text(node, src)
   local num = text and tonumber(text:sub(3, -2)) or nil
   return num and string.char(num) or ""
end

---@param node TSNode
---@param src string
---@return string
H.EntityRef = function(node, src)
   local entity = get_text(node, src)
   return ENTITIES[entity]
end

---@param node TSNode
---@param src string
---@return string
H.CDSect = function(node, src)
   return get_text(node:child(1), src)
end

---@param node TSNode
---@param src string
---@return table
H.content = function(node, src)
   local ret = {}
   if tree_contains(node, "ERROR") then
      return { get_text(node, src) }
   end
   for child in node:iter_children() do
      local T = child:type()
      ret[#ret + 1] = H[T](child, src)
   end
   if not tree_contains(node, "element") then
      return { table.concat(ret) }
   end
   return ret
end

H.EmptyElemTag = H.STag

H.element = function(node, src)
   if node:child(0):type() == "EmptyElemTag" then
      local name, res = H.EmptyElemTag(node:child(0), src)
      return { [name] = res }
   end
   local K, V = H.STag(node:child(0), src)
   for k, v in pairs(V) do
      if k == "type" and v == "xhtml" then
         V[1] = vim.trim(get_text(node:child(1), src))
         return { [K] = V }
      end
   end
   if node:child(1):type() == "ETag" then -- Empty element
      if vim.tbl_isempty(V) then
         return { [K] = "" }
      end
      return { [K] = V }
   end
   local content = H.content(node:child(1), src)
   for _, element in ipairs(content) do
      if type(element) == "table" then
         for k, v in pairs(element) do
            if V[k] then
               if not vim.islist(V[k]) then
                  V[k] = { V[k] }
               end
               table.insert(V[k], v)
            else
               V[k] = v
            end
         end
      elseif type(element) == "string" then -- TODO: handle dup
         table.insert(V, element)
      end
   end
   return { [K] = V }
end

---tree-sitter powered parser to turn markup to simple lua table
---@param src string
---@param url string
---@return table?
local parse = vim.F.nil_wrap(function(src, url)
   ut.assert_parser("xml")
   local root = get_root(src, "xml")
   if root:has_error() then
      log.warn(url, "treesitter err")
   end
   local collected = {}
   for node in root:iter_children() do
      collected[#collected + 1] = H[node:type()](node, src)
   end
   if collected[1].encoding then
      collected[2].encoding = collected[1].encoding
   end
   return #collected == 2 and collected[2] or collected[1]
end)

return { parse = parse }
