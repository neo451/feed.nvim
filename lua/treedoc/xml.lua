local ut = require "treedoc.utils"
local xml = {}

xml.prolog = ut.noop
xml.comment = ut.noop

xml.STag = function(node, src, _)
   local ret = { [ut.get_text(node:child(1), src)] = {} }
   local n = node:child_count()
   if n == 3 then
      return ret
   end
   for i = 2, n - 2 do
      local child = node:child(i)
      if child:type() == "Attribute" then
         local k, v = ut.get_text(child:child(0), src), ut.get_text(child:child(2), src):gsub('"', "")
         local _, V = next(ret)
         V[k] = v
      end
   end
   return ret
end

xml.CharData = function(node, src, _)
   local text = ut.get_text(node, src)
   if text:find "%S" then
      return text
   end
end

xml.ETag = ut.noop

xml.content = function(node, src, rules)
   if not node then
      return {}
   end
   local ret = {}
   for child in node:iter_children() do
      local T = child:type()
      ret[#ret + 1] = rules[T](child, src, rules)
   end
   if not ut.tree_contains(node, "element") then
      return { table.concat(ret) }
   end
   return ret
end

local ENTITIES = {
   ["&lt;"] = "<",
   ["&gt;"] = ">",
   ["&amp;"] = "&",
   ["&apos;"] = "'",
   ["&quot;"] = '"',
}

xml.EntityRef = function(node, src, _)
   local entity = ut.get_text(node, src)
   return ENTITIES[entity]
end

xml.element = function(node, src, rules)
   local ret = rules.STag(node:child(0), src, rules)
   local content = rules.content(node:child(1), src, rules)
   local K, V = next(ret)
   for _, element in ipairs(content) do
      if type(element) == "table" then
         for k, v in pairs(element) do
            if V[k] then
               if not vim.isarray(V[k]) then --TODO:
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

return xml
