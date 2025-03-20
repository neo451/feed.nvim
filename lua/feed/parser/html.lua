local ut = require("feed.utils")
local treesitter = vim.treesitter
local gsub = string.gsub

---@param src string?
---@return string
local function resolve(src, url)
   url = ut.extend_import_url(url)
   if not src then
      return ""
   end
   ut.assert_parser("html")
   local root_node = ut.get_root(src, "html")

   local query_str = [[ (attribute)@kv ]]

   local query = treesitter.query.parse("html", query_str)

   for _, node in query:iter_captures(root_node, src) do
      local link = ut.get_text(node, src):match('src="(%S+)"')
      if link and not ut.looks_like_url(link) then
         src = gsub(src, vim.pesc(link), ut.url_resolve(url, link))
      end
   end

   return src
end

return {
   resolve = resolve,
}
