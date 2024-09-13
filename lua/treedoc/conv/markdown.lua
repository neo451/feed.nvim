local convert

local md = {}

for i = 1, 6 do
   md["h" .. i] = function(node)
      return string.rep("#", i) .. " " .. convert(node[1])
   end
end

md.a = function(node)
   return ("[%s](%s)"):format(node[1], node.href)
end

md.div = function(node)
   local buf = {}
   for i, child in ipairs(node) do
      buf[i] = convert(child)
   end
   return table.concat(buf, "\n")
end

md.ul = function(node)
   local buf = {}
   for i, li in ipairs(node) do
      buf[i] = convert(li)
   end
   return table.concat(buf, "\n")
end

md.ol = function(node)
   local buf = {}
   for i, li in ipairs(node) do
      buf[i] = convert(li, i)
   end
   return table.concat(buf, "\n")
end

local function concat_node(node)
   local buf = {}
   for i, child in ipairs(node) do
      if type(child) == "string" then
         buf[i] = child
      else
         buf[i] = convert(child)
      end
   end
   return table.concat(buf, " ")
end

md.li = function(node, order)
   if order then
      return ("%d. %s"):format(order, concat_node(node))
   else
      return "- " .. convert(node[1])
   end
end

md.img = function(node)
   return "![image](" .. node.src .. ")"
end

md.p = function(node)
   return concat_node(node)
end

md.html = md.p

md.br = function(_)
   -- return " "
   return "\n"
end

md.code = function(node)
   return ("`%s`"):format(node[1])
   --    return ([[```%s
   -- %s
   -- ```]]):format(node.lang, node[1])
end

md.em = function(node)
   return ("*%s*"):format(convert(node[1]))
end

md.strong = function(node)
   return ("**%s**"):format(convert(node[1]))
end

---@param t table | string
function convert(t, ...)
   if type(t) == "string" then
      return t
   end
   if not md[t.tag] then
      print(t.tag, "!!!")
      print(vim.inspect(t))
   end
   return md[t.tag](t, ...)
end

return convert
