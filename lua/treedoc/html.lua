local ut = require "treedoc.utils"
local html = {}

html.attribute = function(node, src, rules)
   return ut.get_text(node:child(0), src), ut.get_text(node:child(2):child(1), src)
end

html.start_tag = function(node, src, rules)
   local ret
   for child in node:iter_children() do
      if child:type() == "tag_name" then
         ret = { [ut.get_text(child, src)] = {} }
      elseif child:type() == "attribute" then
         local _, V = next(ret)
         local k, v = rules.attribute(child, src, rules)
         V[k] = v
      end
   end
   return ret
end

html.text = function(node, src)
   return ut.get_text(node, src)
end

html.end_tag = function(_, _)
   return nil
end

html.element = function(node, src, rules)
   local ret
   for child in node:iter_children() do
      local p_child = rules[child:type()](child, src, rules)
      if child:type() == "start_tag" then
         ret = p_child
      else
         local _, V = next(ret)
         V[#V + 1] = p_child
      end
   end
   return ret
end

html.doctype = function(_, _, _) end

return html
