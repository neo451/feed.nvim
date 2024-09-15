local ut = require "treedoc.utils"

---@alias treedoc.handler fun(node: TSNode, src: string): any

---@type table<string, treedoc.handler>
local xml = {}

local ENTITIES = {
   ["&lt;"] = "<",
   ["&gt;"] = ">",
   ["&amp;"] = "&",
   ["&apos;"] = "'",
   ["&quot;"] = '"',
   -- TODO:?
}

local noop = ut.noop
xml.prolog = noop
xml.comment = noop
xml._Misc = noop
xml.ETag = noop

setmetatable(xml, {
   __index = function(t, k)
      if not rawget(t, k) then
         print(k, " is not handle by the treedoc parser!!")
         return noop
      end
   end,
})

xml.STag = function(node, src)
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

xml.CharData = function(node, src)
   local text = ut.get_text(node, src)
   if text:find "%S" then
      return text
   end
end

xml.CDSect = function(node, src)
   return ut.get_text(node:child(1), src)
end

xml.content = function(node, src)
   if not node then
      return {}
   end
   local ret = {}
   for child in node:iter_children() do
      local T = child:type()
      if not xml[T] then
         print(ut.get_text(node, src), node:type(), node:child_count())
      end
      ret[#ret + 1] = xml[T](child, src)
   end
   if not ut.tree_contains(node, "element") then
      return { table.concat(ret) }
   end
   return ret
end

xml.EntityRef = function(node, src)
   local entity = ut.get_text(node, src)
   return ENTITIES[entity]
end

xml.element = function(node, src)
   if node:child(0):type() == "EmptyElemTag" then
      return xml.STag(node:child(0), src)
   end
   local ret = xml.STag(node:child(0), src)
   if node:child(1):type() == "ETag" then
      return ret -- Empty element
   end
   local content = xml.content(node:child(1), src)
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

local unhandled = {
   "EntityValue",
   "ExternalID",
   "NDataDecl",
   "PseudoAttValue",
   "_Reference",
   "doctypedecl",
   "_ErroneousETag",
   "PublicID",
   "XmlModelPI",
   "_S",
   "StyleSheetPI",
   "CharRef",
   "children",
   "_markupdecl",
   "conditionalSect",
   "_DeclSep",
   "CDStart",
   "PubidLiteral",
   "PseudoAtt",
   "PEReference",
   "elementdecl",
   "AttlistDecl",
   "_EntityDecl",
   "NotationDecl",
   "PI",
   "Name",
   "Attribute",
   "contentspec",
   "EmptyElemTag",
   "Mixed",
   "_intSubset",
   "_choice",
   "_cp",
   "_SDDecl",
   "PEDecl",
   "AttDef",
   "_AttType",
   "DefaultDecl",
   "StringType",
   "TokenizedType",
   "_EnumeratedType",
   "_Eq",
   "EncName",
   "_extSubsetDecl",
   "VersionNum",
   "_VersionInfo",
   "XMLDecl",
   "SystemLiteral",
   "NotationType",
   "Enumeration",
   "Nmtoken",
   "document",
   "_EncodingDecl",
   "AttValue",
   "GEDecl",
}

return xml
