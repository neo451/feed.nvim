local lpeg = require "lpeg"

local L = lpeg.locale()
local P, V, C, Ct, S, R, Cg, Cc = lpeg.P, lpeg.V, lpeg.C, lpeg.Ct, lpeg.S, lpeg.R, lpeg.Cg, lpeg.Cc
local ws = S "\r\n\f\t\v "
local ws0 = ws ^ 0
local ws1 = ws ^ 1

local name = S "_ " + L.digit + L.alpha
local vname = name + S "/.:&-"

local tagStart = P "<"
local tagEnd = P ">"

local singleTagEnd = P "/>"
local pairTagEnd = P "</"

local xmlDefStart = P "<?"
local xmlDefEnd = P "?>"

local commentStart = P "<!--"
local commentEnd = P "-->"

local CDATAStart = P "<![CDATA["
local CDATAEnd = P "]]>"

local singleQuote = P [[']]
local doubleQuote = P [["]]

local qname = (1 - doubleQuote)
local sqname = (1 - singleQuote)

local doctypeName = P "doctype" + P "DOCTYPE"

local rawAttributeName = L.alpha * (L.alpha + L.digit + S "-:_") ^ 0
local rawTagName = L.alpha * (L.alpha + L.digit + S "-_") ^ 0
local rawTagNameN = (rawTagName * P ":") ^ -1 * rawTagName

local rawqvalue = (doubleQuote * qname ^ 0 * doubleQuote) + (singleQuote * sqname ^ 0 * singleQuote) + (1 - ws) ^ 1

local rawAttribute = rawAttributeName * P "=" * rawqvalue + rawAttributeName + doubleQuote * qname ^ 0 * doubleQuote

local rawAttributes = rawAttribute * (ws1 * rawAttribute) ^ 0

local rawTag = tagStart * rawTagNameN * ws0 * singleTagEnd + tagStart * rawTagNameN * (ws1 * rawAttributes) ^ -1 * tagEnd +
pairTagEnd * rawTagNameN * tagEnd

local function elmType(name)
   return Cg(Cc(name), "type")
end

local currentTag = {}

local function setSingleTag(tag)
   if tag.type == "singleTag" or tag.type == "pairTag" then
      --print('<', tag.name, tag.type, '>')
      currentTag.children = currentTag.children or {}
      table.insert(currentTag.children, tag)
      tag.parent = currentTag
   end
   return tag
end

local function startTag(tag)
   if tag.type == "singleTag" or tag.type == "pairTag" then
      --print('<', tag.name)
      if not currentTag then
         currentTag = tag
      else
         currentTag.children = currentTag.children or {}
         table.insert(currentTag.children, tag)
         tag.parent = currentTag
         currentTag = tag
         return
      end
   end
   return tag
end

local function endTag(tag)
   if tag.type == "singleTag" or tag.type == "pairTag" then
      --print('>', tag.name)
      currentTag = currentTag.parent
   end
end

local function processAttributes(attributes)
   local out = {}
   for k, v in pairs(attributes) do
      local name, value = v[1], v[2] or true

      if not out[name] then
         out[name] = value
      else
         if type(out[name]) ~= "table" then
            out[name] = { out[name] }
         end
         table.insert(out[name], value)
      end
   end
   return out
end

local grammar = P {
   "ml",
   ml = V "BOM" * ws0 * (Ct(V "xml" + V "html") * ws0),
   xml = Cg(Ct(V "xmlDef" * ws0 * V "docSkeleton"), "xml"),
   html = Cg(Ct(V "docSkeleton"), "html"),
   docSkeleton = (V "doctype") ^ -1 * ws0 * Cg(V "docBody", "children"),
   -- UTF-8 BOM
   BOM = (P "\xEF\xBB\xBF") ^ -1,
   xmlDef = Cg(Ct(xmlDefStart * P "xml" * ws1 * V "attributes" * ws0 * xmlDefEnd), "xmlDef"),
   doctype = Cg(Ct(P "<!" * doctypeName * ws1 * V "attributes" * ws0 * P ">"), "doctype"),
   docBody = ws0 * V "tags" * ws0,
   tags = Ct((V "tag") ^ 0),
   tag = V "CDATA" / setSingleTag + V "comment" / setSingleTag + V "singleTag" + V "startPairTag" + V "endPairTag" + ws1 + V "text" / setSingleTag,
   singleTag = Ct(tagStart * V "tagName" * ws0 * V "attributes" * ws0 * singleTagEnd * elmType "singleTag") / setSingleTag,
   startPairTag = Ct(tagStart * V "tagName" * ws0 * V "attributes" * ws0 * tagEnd * elmType "pairTag") / startTag,
   endPairTag = Ct(pairTagEnd * ws0 * V "tagName" * tagEnd * elmType "pairTag") / endTag,
   attributes = Cg((Ct(V "attribute" * (ws1 * V "attribute") ^ 0) / processAttributes) ^ -1, "attributes"),
   attribute = Cg(Ct(V "attributeName" * P "=" * (V "qvalue"))) + Cg(Ct(V "attributeName")) + Cg(Ct(Cc "strings" * C(doubleQuote * qname ^ 0 * doubleQuote))),
   qvalue = (doubleQuote * C(qname ^ 0) * doubleQuote) + (singleQuote * C(sqname ^ 0) * singleQuote) + C((1 - ws) ^ 1),
   textElm = Cg(C((1 - rawTag) ^ 1), "content"),
   text = Ct(V "textElm" * elmType "text"),
   CDATAElm = CDATAStart * Cg(C((1 - CDATAEnd) ^ 0), "content") * CDATAEnd,
   CDATA = Ct(V "CDATAElm" * elmType "CDATA"),
   commentElm = Cg(commentStart * Cg(C((1 - commentEnd) ^ 0), "content") * commentEnd, "content"),
   comment = Ct(V "commentElm" * elmType "comment"),
   attributeName = C(L.alpha * (L.alpha + L.digit + S "-:_") ^ 0),
   name = C(rawTagName),
   tagName = (Cg(V "name", "namespace") * P ":") ^ -1 * Cg(V "name", "name"),
}

local function parse(text)
   return grammar:match(text)
end

local ti = table.insert

local function disjunct(a, b)
   local out = {}
   local tmp = {}
   setmetatable(tmp, { __mode = "v" })
   for _, v in ipairs(a) do
      if not tmp[v] then
         ti(out, v)
         tmp[v] = true
      end
   end
   for _, v in ipairs(b) do
      if not tmp[v] then
         ti(out, v)
         tmp[v] = true
      end
   end
   return out
end

local function conjuct(a, b)
   local out = {}
   for _, u in ipairs(a) do
      for _, v in ipairs(b) do
         if u == v then
            ti(out, v)
         end
      end
   end
   return out
end

local function minus(a, b)
   local out = {}
   for _, u in ipairs(a) do
      local found = false
      for _, v in ipairs(b) do
         if u == v then
            found = true
            break
         end
      end
      if not found then
         ti(out, u)
      end
   end
   return out
end

local function filter(t, fn)
   local out = {}
   local function filterRecursive(t)
      if type(t) == "table" then
         local workingSet
         if type(t.children) == "table" and #t.children > 0 then
            workingSet = t.children
         elseif #t > 0 then
            workingSet = t
         elseif t.html then
            workingSet = t.html.children
         elseif t.xml then
            workingSet = t.xml.children
         else
            return
         end

         for _, item in ipairs(workingSet) do
            if fn(item) then
               ti(out, item)
            end
            filterRecursive(item)
         end
      end
   end

   filterRecursive(t)
   return out
end

local function PS(fn)
   local obj = {}
   setmetatable(obj, {
      __add = function(a, b)
         return PS(function(t)
            return disjunct(a(t), b(t))
         end)
      end,
      __sub = function(a, b)
         return PS(function(t)
            return minus(a(t), b(t))
         end)
      end,
      __mul = function(a, b)
         return PS(function(t)
            return conjuct(a(t), b(t))
         end)
      end,
      __div = function(a, b)
         assert(type(b) == "function")
         return PS(function(t)
            return b(a(t))
         end)
      end,
      __call = function(_, t)
         return fn(t)
      end,
   })
   return obj
end

--[[
	A - Tag attribute rule
	A(attributeName) - matches tags with specific attribute
	A({attributeName = attributeValue, ...}) - matches tags with specific attribute value
	A({attributeName = {attributeValue [, matchOperation]}, ...}) - matches tags with specific attribute value with string.match function
	matchOperation can be:
		eq - for simple string equality test
		match - for matching with string.match function
		neq - negation of eq operation
		nmatch - negation of match operation
--]]

local function A(n)
   return PS(function(t)
      return filter(t, function(v)
         local etype = v.type
         local attributes = v.attributes
         local isTag = (etype == "pairTag" or etype == "singleTag")

         if type(attributes) == "table" then
            if type(n) == "string" then
               return isTag and attributes[n]
            elseif type(n) == "table" then
               local total = 0
               local valid = 0

               for k, v in pairs(n) do
                  total = total + 1

                  local value = attributes[k]

                  if not value then
                     return false
                  end

                  if type(v) == "string" then
                     if value == v then
                        valid = valid + 1
                     end
                  elseif type(v) == "number" then
                     if value == v then
                        valid = valid + 1
                     end
                  elseif type(v) == "table" and type(value) == "string" then
                     local pattern = v[1]
                     local op = v[2]
                     assert(type(pattern) == "string")

                     if type(op) == "string" then
                        if op == "eq" then
                           if value == v then
                              valid = valid + 1
                           end
                        elseif op == "match" then
                           if value:match(pattern) then
                              valid = valid + 1
                           end
                        elseif op == "neq" then
                           if value ~= v then
                              valid = valid + 1
                           end
                        elseif not op == "nmatch" then
                           if value:match(pattern) then
                              valid = valid + 1
                           end
                        end
                     elseif type(op) == "function" then
                        if op(value, v) then
                           valid = valid + 1
                        end
                     else
                        if value:match(pattern) then
                           valid = valid + 1
                        end
                     end
                  end
               end

               return isTag and (valid == total)
            end
         else
            return false
         end
      end)
   end)
end

--[[
	T - Tag name rule
	T(tagName) - matches tags with specific name
--]]
local function T(n)
   return PS(function(t)
      return filter(t, function(v)
         local etype = v.type
         local isTag = (etype == "pairTag" or etype == "singleTag")

         if type(n) == "string" then
            return isTag and (v.name == n)
         else
            return isTag
         end
      end)
   end)
end

--[[
	F - Flatten tags
	Flattens html tree structure into simple array
	
	rules / F
--]]
local function F(t)
   return filter(t, function(v)
      return true
   end)
end

local function _Txt(t)
   return filter(t, function(v)
      local etype = v.type
      return etype and (etype == "text" or etype == "CDATA")
   end)
end

--[[
	Txt - Text content
	
	Merges text html content into one string
	rules / Txt
--]]
local function Txt(t)
   local t1 = _Txt(t)
   local out = {}

   for _, v in ipairs(t1) do
      if type(v.content) == "string" then
         ti(out, v.content)
      end
   end

   local result = table.concat(out)
   return result
end

-- pp(F(parse(table.concat(vim.fn.readfile "/home/n451/Plugins/rss.nvim/data/html_to_md.html"))))

return {
   parse = parse,
   A = A,
   T = T,
   F = F,
   Txt = Txt,
}
