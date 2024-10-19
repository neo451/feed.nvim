local ut = require "treedoc.utils"

local M = {}

local ENTITIES = {
   ["&lt;"] = "<",
   ["&gt;"] = ">",
   ["&amp;"] = "&",
   ["&apos;"] = "'",
   ["&quot;"] = '"',
}

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
            print(k, " is not handle by the treedoc parser!!")
         end
         return noop
      end
   end,
})

---@param node TSNode
---@param src string
---@return table<string, string | table>
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
   if text:find "%S" then
      return text
   end
end

M.CDSect = function(node, src)
   return ut.get_text(node:child(1), src)
end

---@param node TSNode
---@param src string
---@return table<string, table>
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

M.element = function(node, src)
   if node:child(0):type() == "EmptyElemTag" then
      return M.STag(node:child(0), src)
   end
   local ret = M.STag(node:child(0), src)
   if node:child(1):type() == "ETag" then
      return ret -- Empty element
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
      else
         if vim.tbl_isempty(ret[K]) then
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
---@return table
function M.parse(src)
   local root = ut.get_root(src, "xml")
   local iterator = vim.iter(root:iter_children())
   local collected = iterator:fold({}, function(acc, node)
      local T = node:type()
      if not M[T] then
         print(T)
      end
      acc[#acc + 1] = M[T](node, src)
      return acc
   end)
   return collected[1]
end

return M
