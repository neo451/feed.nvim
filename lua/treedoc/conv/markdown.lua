local convert

---@alias Node { tag : string, [number] : Node | string, href : string, src : string, class : string }

---@alias treedoc.nodehandler fun(node: Node, context: any): string?

---@type table<string, treedoc.nodehandler>
local md = {}

setmetatable(md, {
   __index = function(t, k)
      print(k)
      if not rawget(t, k) then
         return function(node)
            print(vim.inspect(node))
            return "<<" .. node.tag .. ">>"
         end
      end
   end,
})

for i = 1, 6 do
   md["h" .. i] = function(node)
      return "\n" .. string.rep("#", i) .. " " .. convert(node[1]) .. "\n"
   end
end

md.a = function(node)
   return ("[%s](%s)"):format(convert(node[1]), node.href)
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

md.figure = concat_node

-- TODO: center this
md.figcaption = function(node)
   return concat_node(node, "\n") .. "\n"
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

-- TODO:
md.hr = function(_)
   return "\n==================================================\n"
end

md.code = function(node)
   if node.class then
      return ("\n```%s\n%s\n```\n"):format(node.class:sub(10, #node.class), concat_node(node, " "))
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

md.blockquote = function(node, _)
   return "\n>  " .. concat_node(node) .. "\n"
end

-- TODO: proper color?
md.span = function(node, _)
   return convert(node[1])
end

-- TODO: why not showing
-- md.dl = function(node)
--    local buf = {}
--    for i = #node, 2 do
--       local title, desc = node[i], node[i + 1]
--       buf[#buf + 1] = title[1]
--       buf[#buf + 1] = "\n"
--       buf[#buf + 1] = "    " .. desc[1]
--       buf[#buf + 1] = "\n"
--    end
--    return table.concat(buf)
-- end

-- TODO: more robust rendering, handle very long lines
md.table = function(node)
   local buf = { "\n" }
   local b = {}
   local deli = { "|" }
   for i, tr in ipairs(node) do
      for _, t in ipairs(tr) do
         b[#b + 1] = "| " .. (t[1] or " ")
         if i == 1 then
            deli[#deli + 1] = "--|"
         end
      end
      b[#b + 1] = "|"
      buf[#buf + 1] = table.concat(b)
      if i == 1 then
         buf[#buf + 1] = table.concat(deli)
      end
      b = {}
   end
   buf[#buf + 1] = "\n"
   return table.concat(buf, "\n")
end

---@param t table | string
function convert(t, ...)
   if type(t) == "string" then
      return t
   end
   return md[t.tag](t, ...)
end

return convert
