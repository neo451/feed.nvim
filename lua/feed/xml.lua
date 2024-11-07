local log = require "feed.log"
local build = require "feed.build"
local lpeg = vim.lpeg
local P, C, Ct = lpeg.P, lpeg.C, lpeg.Ct

build.build()

local M = {}

local get_text = function(node, src)
   if not node then
      return "empty node"
   end
   return vim.treesitter.get_node_text(node, src)
end

---@param str string
---@return TSNode
local get_root = function(str, language)
   local parser = vim.treesitter.get_string_parser(str, language)
   return parser:parse()[1]:root()
end

local tree_contains = function(node, T)
   for child in node:iter_children() do
      if child:type() == T then
         return true
      end
   end
   return false
end

local ENTITIES = {
   ["&lt;"] = "<",
   ["&gt;"] = ">",
   ["&amp;"] = "&",
   ["&apos;"] = "'",
   ["&quot;"] = '"',
}

local r_ENTITIES = {
   { "&", "&amp;" }, -- TODO: not preceded by #
   { "<", "&lt;" },
   { ">", "&gt;" },
   { "'", "&apos;" },
   { '"', "&quot;" },
}

local function repl_entity(str)
   for _, v in ipairs(r_ENTITIES) do
      if str:find(v[1]) then
         str = str:gsub(v[1], v[2])
      end
   end
   return str
end

local function gen_tag_rule(tag)
   local st = P("<" .. tag .. ">")
   local et = P("</" .. tag .. ">")
   local rule = C(st) * ((1 - et) ^ 0 / repl_entity) * C(et)
   return rule
end

local cdata = P "<![CDATA[" * ((1 - lpeg.P "]]>") ^ 0 / repl_entity) * lpeg.P "]]>"

local function gen_extract_pat(rule)
   return Ct((C((1 - rule) ^ 0) * rule ^ 1 * C((1 - rule) ^ 0)) ^ 1)
end

local rm_text = function(str)
   local res = gen_extract_pat(gen_tag_rule "title"):match(str)
   if res and not vim.tbl_isempty(res) then
      return table.concat(res)
   end
   return str
end

local rm_cdata = function(str)
   local res = gen_extract_pat(cdata):match(str)
   if res and not vim.tbl_isempty(res) then
      return table.concat(res)
   end
   return str
end

function M.sanitize(str)
   return rm_text(rm_cdata(str))
end

setmetatable(M, {
   __index = function(t, k)
      if not rawget(t, k) then
         if vim.g.treedoc_debug then
            print(k, " is not handle by the feed.xml parser!!")
         end
         return function() end
      end
   end,
})

---@param node TSNode
---@param src string
---@return string
---@return table | string
M.STag = function(node, src)
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

M.CharData = function(node, src)
   local text = get_text(node, src)
   if text:find "%S" then
      return text
   end
end

M.CDSect = function(node, src)
   return get_text(node:child(1), src)
end

---@param node TSNode
---@param src string
---@return table | string
M.content = function(node, src)
   local ret = {}
   for child in node:iter_children() do
      local T = child:type()
      if not M[T] then
         print(get_text(node, src), node:type(), node:child_count())
      end
      ret[#ret + 1] = M[T](child, src)
   end
   if not tree_contains(node, "element") then
      return { table.concat(ret) }
   end
   return ret
end

M.EntityRef = function(node, src)
   local entity = get_text(node, src)
   return ENTITIES[entity]
end

M.EmptyElemTag = M.STag

M.element = function(node, src)
   if node:child(0):type() == "EmptyElemTag" then
      local name, res = M.EmptyElemTag(node:child(0), src)
      return { [name] = res }
   end
   local K, V = M.STag(node:child(0), src)
   if node:child(1):type() == "ETag" then -- Empty element
      if vim.tbl_isempty(V) then
         return { [K] = "" }
      end
      return { [K] = V }
   end
   local content = M.content(node:child(1), src)
   for _, element in ipairs(content) do
      if type(element) == "table" then
         for k, v in pairs(element) do
            if V[k] then
               if not vim.islist(V[k]) then --TODO:
                  V[k] = { V[k] }
               end
               table.insert(V[k], v)
            else
               V[k] = v
            end
         end
      elseif type(element) == "string" then
         if vim.tbl_isempty(V) then
            V = element
         else
            table.insert(V, element)
         end
      end
   end
   return { [K] = V }
end

---tree-sitter powered parser to turn markup to simple lua table
---@param src string
---@param name string?
---@return table
function M.parse(src, name)
   src = M.sanitize(src)
   local root = get_root(src, "xml")
   if root:has_error() then
      log.warn("ts error: feed", name, "did not return a valid xml file")
   end
   local iterator = vim.iter(root:iter_children())
   local collected = iterator:fold({}, function(acc, node)
      acc[#acc + 1] = M[node:type()](node, src)
      return acc
   end)
   return collected[1]
end

return M
