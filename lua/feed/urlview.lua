---1. view all links and open them through vim.ui.select or telescope, inspired by `newsboat`'s link listing feature and `urlview.nvim`
---2. remove the actual link in the file, so that conceal and wrap does not conflict

---@diagnostic disable: param-type-mismatch
local inline_query = vim.treesitter.query.parse("markdown_inline", [[(inline_link)@link]])
local auto_query = vim.treesitter.query.parse("markdown_inline", [[(uri_autolink)@link]])
local image_query = vim.treesitter.query.parse("markdown_inline", [[(image)@image]])

local get_root = function(str)
   local parser = vim.treesitter.get_string_parser(str, "markdown_inline")
   return parser:parse()[1]:root()
end

local get_text = vim.treesitter.get_node_text
local image_count = 0

local function get_links(str)
   local res_str = str
   local res = {}
   local root = get_root(str)

   for _, node in image_query:iter_captures(root, str) do
      local link = get_text(node:child(5), str)
      image_count = image_count + 1
      local text = "image " .. image_count
      res_str = res_str:gsub("%(" .. vim.pesc(link) .. "%)", "", 1)
      res_str = res_str:gsub("image", text, 1)
      res[#res + 1] = { text, link }
   end

   for _, node in inline_query:iter_captures(root, str) do
      local text = get_text(node:child(1), str)
      local link = get_text(node:child(4), str)
      res_str = res_str:gsub("%(" .. vim.pesc(link) .. "%)", "", 1)
      res[#res + 1] = { text, link }
   end

   for _, node in auto_query:iter_captures(root, str) do
      local link = get_text(node, str):sub(2, -2)
      res[#res + 1] = { link, link }
   end

   return res_str, res
end

local function urlview(lines)
   local ret_links = {}
   for i, v in ipairs(lines) do
      local line, links = get_links(v)
      lines[i] = line
      vim.list_extend(ret_links, links)
   end
   image_count = 0
   return lines, ret_links
end

return urlview
