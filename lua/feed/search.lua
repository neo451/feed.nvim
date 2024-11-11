local date = require "feed.date"

local M = {}

local filter_symbols = {
   ["+"] = "must_have",
   ["-"] = "must_not_have",
   ["@"] = "date",
   ["#"] = "limit",
   ["="] = "feed",
}

---@param str string
---@return feed.query
function M.parse_query(str)
   if str == "" or not str then
      return {}
   end
   local query = {}
   for q in vim.gsplit(str, " ") do
      local kind = filter_symbols[q:sub(1, 1)] or "re"
      if kind == "date" then
         query.after, query.before = date.new_from.filter(q)
      elseif kind == "re" then
         if q ~= "" then
            if not query.re then
               query.re = {}
            end
            table.insert(query.re, q)
         end
      elseif kind == "feed" then
         query.feed = q:sub(2) -- TODO: ! weird for now =!neovim
      elseif kind == "must_have" then
         if not query.must_have then
            query.must_have = {}
         end
         table.insert(query.must_have, q:sub(2))
      elseif kind == "must_not_have" then
         if not query.must_not_have then
            query.must_not_have = {}
         end
         table.insert(query.must_not_have, q:sub(2))
      elseif kind == "limit" then
         query.limit = tonumber(q:sub(2))
      end
   end
   return query
end

-- TODO: build query string

-- TODO: memoize
function M.build_regex(str)
   local rev = str:sub(0, 1) == "!"
   if rev then
      str = str:sub(2)
   end
   local q = vim.regex(str .. "\\c")
   return q, rev
end

return M
