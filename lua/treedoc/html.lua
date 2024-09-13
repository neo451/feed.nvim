local ut = require "treedoc.utils"
local html = {}

local get_text = ut.get_text

setmetatable(html, {
   __index = function(t, k)
      if not rawget(t, k) then
         print(k)
      end
   end,
})

local ENTITIES = {
   ["&lt;"] = "<",
   ["&gt;"] = ">",
   ["&amp;"] = "&",
   ["&apos;"] = "'",
   ["&quot;"] = '"',
   -- TODO:?
}

html.entity = function(node, src)
   local text = get_text(node, src)
   return ENTITIES[text]
end

html.attribute = function(node, src)
   return ut.get_text(node:child(0), src), ut.get_text(node:child(2):child(1), src)
end

html.start_tag = function(node, src)
   local tag = ut.get_text(node:child(1), src)
   local attrs = {}
   for child in node:iter_children() do
      if child:type() == "attribute" then
         local k, v = html.attribute(child, src)
         attrs[k] = v
      end
   end
   return tag, attrs
end

html.text = function(node, src)
   return ut.get_text(node, src)
end

html.end_tag = function(_, _)
   return nil
end

html.element = function(node, src)
   local tag, attrs = html.start_tag(node:child(0), src)
   local n = node:child_count()
   local res = {}
   for i = 1, n - 2 do
      local child = node:child(i)
      res[#res + 1] = html[child:type()](child, src)
   end
   res = vim.tbl_extend("force", res, attrs)
   res.tag = tag
   return res
end

html.doctype = function(_, _, _) end

return html
