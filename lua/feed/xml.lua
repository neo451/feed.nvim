local ut = require "treedoc.utils"
local log = require "feed.log"
local lpeg = vim.lpeg
local P, C, Ct = lpeg.P, lpeg.C, lpeg.Ct

local M = {}

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

local noop = ut.noop
M.prolog = noop
M.comment = noop
M._Misc = noop
M.ETag = noop
M.CharRef = noop

setmetatable(M, {
   __index = function(t, k)
      if not rawget(t, k) then
         if vim.g.treedoc_debug then
            print(k, " is not handle by the feed.xml parser!!")
         end
         return noop
      end
   end,
})

---@param node TSNode
---@param src string
---@return table<string, table>
M.STag = function(node, src)
   local ret = { [ut.get_text(node:child(1), src)] = {} }
   local n = node:child_count()
   if n == 3 then
      return ret
   end
   for i = 2, n - 2 do
      local child = node:child(i)
      if child and child:type() == "Attribute" then
         local k, v = ut.get_text(child:child(0), src), ut.get_text(child:child(2), src):gsub('"', "")
         local _, V = next(ret)
         V[k] = v
      end
   end
   return ret
end

M.CharData = function(node, src)
   local text = ut.get_text(node, src)
   -- return text
   if text:find "%S" then
      return text
   end
end

M.CDSect = function(node, src)
   return ut.get_text(node:child(1), src)
end

---@param node TSNode
---@param src string
---@return table | string
M.content = function(node, src)
   if not node then
      return {}
   end
   local ret = {}
   for child in node:iter_children() do
      local T = child:type()
      if not M[T] then
         print(ut.get_text(node, src), node:type(), node:child_count())
      end
      ret[#ret + 1] = M[T](child, src)
   end
   if not ut.tree_contains(node, "element") then
      return { table.concat(ret) }
   end
   return ret
end

M.EntityRef = function(node, src)
   local entity = ut.get_text(node, src)
   return ENTITIES[entity]
end

M.EmptyElemTag = function(node, src)
   local ret = { [ut.get_text(node:child(1), src)] = {} }
   local n = node:child_count()
   if n == 3 then
      return { [ut.get_text(node:child(1), src)] = "" }
   end
   for i = 2, n - 2 do
      local child = node:child(i)
      if child and child:type() == "Attribute" then
         local k, v = ut.get_text(child:child(0), src), ut.get_text(child:child(2), src):gsub('"', "")
         local _, V = next(ret)
         V[k] = v
      end
   end
   return ret
end

M.element = function(node, src)
   if node:child(0):type() == "EmptyElemTag" then
      return M.EmptyElemTag(node:child(0), src)
   end
   local ret = M.STag(node:child(0), src)
   if node:child(1):type() == "ETag" then -- Empty element
      local k, v = next(ret)
      if vim.tbl_isempty(v) then
         ret[k] = ""
      end
      return ret
   end
   local content = M.content(node:child(1), src)
   local K, V = next(ret)
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
            ret[K] = element
         else
            table.insert(V, element)
         end
      end
   end
   return ret
end

---tree-sitter powered parser to turn markup to simple lua table
---@param src string
---@param name string?
---@return table
function M.parse(src, name)
   src = M.sanitize(src)
   local root = ut.get_root(src, "xml")
   -- if root:has_error() then
   --    -- local f = io.open("_" .. name, "w")
   --    -- f:write(src)
   --    -- f:close()
   --    -- log.warn("ts error: feed %s did not return a valid xml file", name)
   --    error(("ts error: feed %s did not return a valid xml file"):format(name), 2)
   -- end
   local iterator = vim.iter(root:iter_children())
   local collected = iterator:fold({}, function(acc, node)
      acc[#acc + 1] = M[node:type()](node, src)
      return acc
   end)
   return collected[1]
end

return M
