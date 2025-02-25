local ut = require("feed.utils")
local treesitter = vim.treesitter
local rsshub = require("feed.integrations.rsshub")

local function escape_pattern(text)
   return '"' .. text:gsub("([%%%.%[%]%(%)%$%^%+%-%*%?])", "%%%1") .. '"' -- Escape all magic characters in the pattern
end

---@param src string?
---@return string
local function resolve(src, url)
   url = rsshub(url)
   if not src then
      return ""
   end
   ut.assert_parser("html")
   local root_node = ut.get_root(src, "html")

   local query_str = [[
   (attribute)@kv
   ]]

   local query = treesitter.query.parse("html", query_str)

   local links = {}

   for _, node in query:iter_captures(root_node, src) do
      local link = ut.get_text(node, src):match('src="(%S+)"')
      if link and not ut.looks_like_url(link) then
         links[#links + 1] = link
      end
   end

   for _, link in ipairs(links) do
      src = string.gsub(src, escape_pattern(link), '"' .. ut.url_resolve(url, link) .. '"')
   end

   return src
end

return {
   resolve = resolve,
}
