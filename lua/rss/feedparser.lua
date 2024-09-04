local M = {}
local treedoc = require "treedoc"

---check if json
---@param str string
---@return boolean
local function is_json(str)
   local ok = pcall(vim.json.decode, str)
   return ok
end

---@alias rss.feed_type "rss" | "atom" | "json" | "opml"

---@class rss.parse.opts
---@field type rss.feed_type

---parse feed fetch from source
---@param src string
---@param opts? {type : rss.feed_type, converter : "md" | "org" | "norg" }
---@return table
---@return rss.feed_type
function M.parse(src, opts)
   opts = opts or {}
   if opts.type == "json" or is_json(src) then
      return vim.json.decode(src), "json"
   elseif opts.type == "opml" then
      local path = vim.fn.expand(src)
      local str = table.concat(vim.fn.readfile(path))
      return treedoc.parse(str, { language = "xml" })[1].opml.body.outline, "opml"
   end
   local body = treedoc.parse(src, { language = "xml" })[1]
   if body.rss then
      return body.rss, "rss"
   else
      return body.feed, "atom"
   end
end

return M
