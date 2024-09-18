local M = {}
local ut = require "treedoc.utils"

-- https://hackage.haskell.org/package/pandoc-types-1.23.1/docs/Text-Pandoc-Definition.html#t:Block

M.rules = {}

-- TODO: lazy load handlers
M.rules.html = require "treedoc.html"
M.rules.xml = require "treedoc.xml"

-- IDEA: none-ls tidy for tidying markup??

---tree-sitter powered parser to turn markup to simple lua table
---@param src string
---@param opts { rules: table, language: string }
---@return table
function M.parse(src, opts)
   opts = opts or {}
   local rules = opts.rules or M.rules[opts.language]
   local root = ut.get_root(src, opts.language)
   local iterator = vim.iter(root:iter_children())
   local collected = iterator:fold({}, function(acc, node)
      local T = node:type()
      if not rules[T] then
         print(T)
      end
      acc[#acc + 1] = rules[T](node, src, rules)
      return acc
   end)
   return collected
end

return M
