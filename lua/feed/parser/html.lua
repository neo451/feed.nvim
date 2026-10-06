local ts = require("feed.treesitter")
local treesitter = vim.treesitter
local gsub = string.gsub
local URL = require("feed.url")

---@param src string?
---@return string
local function resolve(src, url)
   url = URL.extend_import_url(url)
   if not src then
      return ""
   end
   ts.assert_parser("html")
   local root_node = ts.get_root(src, "html")

   local query_str = [[ (attribute)@kv ]]

   local query = treesitter.query.parse("html", query_str)

   for _, node in query:iter_captures(root_node, src) do
      local link = ts.get_text(node, src):match('src="(%S+)"')
      if link and not URL.looks_like_url(link) then
         src = gsub(src, vim.pesc(link), URL.url_resolve(url, link))
      end
   end

   return src
end

return {
   resolve = resolve,
}
