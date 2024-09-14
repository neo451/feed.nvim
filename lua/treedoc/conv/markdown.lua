local convert

---@alias Node { tag : string, [number] : Node | string, href : string, src : string, class : string }

---@alias treedoc.nodehandler fun(node: Node, context: any): string?

---@type table<string, treedoc.nodehandler>
local md = {}

setmetatable(md, {
   __index = function(t, k)
      if not rawget(t, k) then
         return function(node)
            return "<<" .. node.tag .. ">>"
         end
      end
   end,
})

for i = 1, 6 do
   md["h" .. i] = function(node)
      return string.rep("#", i) .. " " .. convert(node[1]) .. "\n"
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

md.pre = md.div

md.ul = function(node)
   local buf = { "\n" }
   for i, li in ipairs(node) do
      buf[i] = convert(li)
   end
   buf[#buf + 1] = "\n"
   return table.concat(buf, "\n")
end

md.ol = function(node)
   local buf = { "\n" }
   for i, li in ipairs(node) do
      buf[i] = convert(li, i)
   end
   buf[#buf + 1] = "\n"
   return table.concat(buf, "\n")
end

---like table.concat, buf converts node
---@param node any
---@param sep any
---@return string
local function concat_node(node, sep)
   sep = sep or " "
   local buf = {}
   for i, child in ipairs(node) do
      buf[i] = convert(child)
   end
   return table.concat(buf, sep)
end

md.li = function(node, order)
   if order then
      return ("%d. %s"):format(order, concat_node(node))
   else
      return "- " .. convert(node[1])
   end
end

md.img = function(node)
   return "\n![image](" .. node.src .. ")\n"
end

md.p = function(node)
   return concat_node(node)
end

md.html = md.p

md.br = function(_)
   return "\n"
end

md.code = function(node)
   if node.class then
      return ("```%s\n%s\n```\n"):format(node.class:sub(10, #node.class), concat_node(node, "\n"))
   end
   return ("`%s`"):format(node[1])
end

md.em = function(node)
   return ("*%s*"):format(convert(node[1]))
end

md.strong = function(node)
   return ("**%s**"):format(convert(node[1]))
end

md.script_element = function(_) end

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
