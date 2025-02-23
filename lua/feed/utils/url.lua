local M = {}
local URL = require("feed.lib.url")
local vim = vim
local ipairs, tostring = ipairs, tostring
local ut = require("feed.utils.shared")

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
---@param src string
---@return string[][]?
M.get_urls = vim.F.nil_wrap(function(src, cur_link)
   local ret = {}

   if cur_link then
      ret[1] = { cur_link, cur_link }
   end

   local lang = "markdown_inline"
   local q = vim.treesitter.query.get(lang, "highlights")
   local tree = vim.treesitter.get_string_parser(src, lang, {}):parse()[1]:root()
   if q then
      for _, match, metadata in q:iter_matches(tree, src) do
         for id, nodes in pairs(match) do
            nodes = ut.listify(nodes)
            for _, node in ipairs(nodes) do
               local url = metadata[id] and metadata[id].url
               if url and match[url] then
                  for _, n in
                     ipairs(ut.listify(match[url] --[[@as TSNode[] ]]))
                  do
                     local link = vim.treesitter.get_node_text(n, src, { metadata = metadata[url] })
                     if link:match("^<%S+>$") then
                        link = link:sub(2, -2)
                     end
                     local res = { link, link }
                     if node:type() == "inline_link" and node:child(1):type() == "link_text" then
                        local text = vim.treesitter.get_node_text(node:child(1), src, { metadata = metadata[url] })
                        res[1] = text
                     elseif node:type() == "image" and node:child(2):type() == "image_description" then
                        ---@diagnostic disable-next-line: param-type-mismatch
                        local text = vim.treesitter.get_node_text(node:child(2), src, { metadata = metadata[url] })
                        res[1] = text
                     end
                     ret[#ret + 1] = res
                  end
               end
            end
         end
      end
   end
   return ret
end)

local function escape_pattern(text)
   return "%(" .. text:gsub("([%%%.%[%]%(%)%$%^%+%-%*%?])", "%%%1") .. "%)" -- Escape all magic characters in the pattern
end

---@param body string
---@param id string
---@return string
M.remove_urls = function(body, id)
   local text_n_links = M.get_urls(body, require("feed.db")[id].link)
   for _, v in ipairs(text_n_links) do
      if not v[1]:find("^Image") then
         local link = escape_pattern(v[2])
         body = string.gsub(body, link, "()")
      end
   end
   return body
end

---@param body string
---@param id string
---@return string
M.resolve_urls = function(body, id)
   local base = require("feed.db")[id].link
   local text_n_links = M.get_urls(body)
   for _, v in ipairs(text_n_links) do
      local link = v[2]
      local resolved = link
      if not M.looks_like_url(link) then
         resolved = M.url_resolve(base, link)
      end
      if resolved and M.looks_like_url(resolved) and resolved ~= base then
         body = string.gsub(body, escape_pattern(link), "(" .. resolved .. ")")
      end
   end
   return body
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
