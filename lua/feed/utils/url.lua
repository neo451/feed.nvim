local M = {}
local URL = require "feed.lib.url"
local vim = vim
local fn = vim.fn
local ipairs, tostring = ipairs, tostring

---@param base_url string
---@param url string
---@return string?
M.url_resolve = function(base_url, url)
   if not base_url then
      return url
   end
   if not url then
      return base_url
   end
   return tostring(URL.resolve(base_url, url))
end

---@param el table
---@param base_uri string
---@return string
M.url_rebase = function(el, base_uri)
   local xml_base = el["xml:base"]
   if not xml_base then
      return base_uri
   end
   return tostring(M.url_resolve(base_uri, xml_base))
end

--- Returns all URLs in markdown buffer, if any.
---@param buf integer
---@return string[][]
M.get_buf_urls = function(buf, cur_link)
   vim.bo[buf].modifiable = true
   local ret = { { cur_link, cur_link } }

   local lang = "markdown_inline"
   local q = vim.treesitter.query.get(lang, "highlights")
   local tree = vim.treesitter.get_parser(buf, lang, {}):parse()[1]:root()
   if q then
      for _, match, metadata in q:iter_matches(tree, buf) do
         for id, nodes in pairs(match) do
            for _, node in ipairs(nodes) do
               local url = metadata[id] and metadata[id].url
               if url and match[url] then
                  for _, n in
                  ipairs(match[url] --[[@as TSNode[] ]])
                  do
                     local link = vim.treesitter.get_node_text(n, buf, { metadata = metadata[url] })
                     if node:type() == "inline_link" and node:child(1):type() == "link_text" then
                        ---@diagnostic disable-next-line: param-type-mismatch
                        local text = vim.treesitter.get_node_text(node:child(1), buf, { metadata = metadata[url] })
                        local row = node:child(1):range() + 1
                        ret[#ret + 1] = { text, link }
                        local sub_pattern = row .. "s/(" .. fn.escape(link, "/~") .. ")//ge"
                        vim.cmd(sub_pattern)
                     elseif node:type() == "image" and node:child(2):type() == "image_description" then
                        ---@diagnostic disable-next-line: param-type-mismatch
                        local text = vim.treesitter.get_node_text(node:child(2), buf, { metadata = metadata[url] })
                        ret[#ret + 1] = { text, link }
                     else
                        ret[#ret + 1] = { link, link }
                     end
                  end
               end
            end
         end
      end
   end
   vim.bo[buf].modifiable = false
   return ret
end

---@param url string
---@param base string
M.resolve_and_open = function(url, base)
   if not M.looks_like_url(url) then
      local link = M.url_resolve(base, url)
      if link then
         vim.ui.open(link)
      end
   else
      vim.ui.open(url)
   end
end

M.looks_like_url = function(str)
   return vim.startswith(str, "http")
end

return M
