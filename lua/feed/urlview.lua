---view all links and open them through vim.ui.select or telescope, inspired by `newsboat`'s link listing feature and `urlview.nvim`

local inline_query = vim.treesitter.query.parse("markdown_inline", [[(inline_link)@link]])
local auto_query = vim.treesitter.query.parse("markdown_inline", [[(uri_autolink)@link]])

local get_root = function(str)
   local parser = vim.treesitter.get_string_parser(str, "markdown_inline")
   return parser:parse()[1]:root()
end

local get_text = vim.treesitter.get_node_text

local function markdown_links(str)
   local inline_links = vim.iter(inline_query:iter_captures(get_root(str), str))
      :map(function(_, node)
         local text = get_text(node:child(1), str)
         local link = get_text(node:child(4), str)
         return text, link
      end)
      :totable()
   local autolinks = vim.iter(auto_query:iter_captures(get_root(str), str))
      :map(function(_, node)
         local text = get_text(node, str):sub(2, -2)
         return text, text
      end)
      :totable()
   return vim.list_extend(inline_links, autolinks)
end

local urlview = function(str)
   local items = markdown_links(str)
   vim.ui.select(items, {
      prompt = "urlview",
      format_item = function(item)
         return item[1]
      end,
   }, function(item, _)
      if item then
         vim.ui.open(item[2])
      end
   end)
end

return urlview
