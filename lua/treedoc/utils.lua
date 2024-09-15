local ut = {}

function ut.noop() end

ut.tree_contains = function(node, T)
   for child in node:iter_children() do
      if child:type() == T then
         return true
      end
   end
   return false
end

---@param str string
---@return TSNode
ut.get_root = function(str, language)
   local parser = vim.treesitter.get_string_parser(str, language)
   return parser:parse()[1]:root()
end

---@param node TSNode?
---@param src string
---@return string
ut.get_text = function(node, src)
   if not node then
      return "empty node"
   end
   return vim.treesitter.get_node_text(node, src)
end

local Path = require "plenary.path"

---@param p string # path to parser's grammar.json
ut.list_unhandled_tags = function(p, rules)
   local path = Path:new(p)
   local str = path:read()
   local tab = vim.json.decode(str)
   local target_rules = vim.iter(vim.tbl_keys(tab.rules))
   target_rules = target_rules:filter(function(k)
      return rules[k] == nil
   end)
   return target_rules:totable()
end

return ut
