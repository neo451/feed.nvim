local M = {}

M.assert_parser = function(name)
   local lib_not_installed = "tree-sitter-" .. name .. " not found."
   assert(pcall(vim.treesitter.language.inspect, name), lib_not_installed)
end

M.get_text = function(node, src)
   if not node then
      return "empty node"
   end
   return vim.treesitter.get_node_text(node, src)
end

---@param str string
---@return TSNode
M.get_root = function(str, language)
   M.assert_parser(language)
   local parser = vim.treesitter.get_string_parser(str, language)
   return parser:parse()[1]:root()
end

M.tree_contains = function(node, T)
   for child in node:iter_children() do
      if child:type() == T then
         return true
      end
   end
   return false
end

return M
