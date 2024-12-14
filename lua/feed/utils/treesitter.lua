local M = {}

function M.assert_parser(name)
   local res, _ = pcall(vim.treesitter.language.inspect, name)
   local lib_not_installed = "tree-sitter-" .. name .. " not found."
   assert(res, lib_not_installed)
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
   local ok, parser = pcall(vim.treesitter.get_string_parser, str, language)
   if not ok then
      error "xml TS parser not found"
   end
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
