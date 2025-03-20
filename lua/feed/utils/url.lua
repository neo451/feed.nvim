local M = {}
local URL = require("feed.lib.url")
local vim = vim
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
---@param cur_link string
---@return string[][]
M.get_urls = function(cur_link)
   local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
   local res = { cur_link }
   for _, line in ipairs(lines) do
      if line:match("^%[%d+%] %s*") then
         local url = line:match("%[%d+%] %s*(%S+)")
         table.insert(res, url)
      end
   end
   return res
end

M.looks_like_url = function(str)
   return vim.startswith(str, "http")
end

M.extend_import_url = function(url)
   local config = require("feed.config")
   if not M.looks_like_url(url) then
      for _, extension in ipairs(config.url_formats) do
         if url:find(extension.pattern) then
            return extension.import(url)
         end
      end
   end
   return url
end

M.extend_export_url = function(url)
   local config = require("feed.config")
   if not M.looks_like_url(url) then
      for _, extension in ipairs(config.url_formats) do
         if url:find(extension.pattern) then
            local f = extension.export or extension.import
            return f(url)
         end
      end
   end
   return url
end

return M
