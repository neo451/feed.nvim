local date = require "feed.parser.date"

local M = {}

---@class feed.query
---@field after? integer #@
---@field before? integer #@
---@field must_have? string[] #+
---@field must_not_have? string[] #-
---@field feed? string #=
---@field limit? number ##
---@field re? string[]

local filter_symbols = {
   ["+"] = "must_have",
   ["-"] = "must_not_have",
   ["@"] = "date",
   ["#"] = "limit",
   ["="] = "feed",
}

-- TODO: memoize
local function build_regex(str)
   -- local rev = str:sub(0, 1) == "!"
   -- if rev then
   --    str = str:sub(2)
   -- end
   local q = vim.regex(str .. "\\c")
   return q
end

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
         local ok, after, before = pcall(date.parse_filter, q)
         if ok then
            query.after = after
            query.before = before
         end
      elseif kind == "re" then
         if q ~= "" then
            if not query.re then
               query.re = {}
            end
            table.insert(query.re, build_regex(q))
         end
      elseif kind == "feed" then
         query.feed = build_regex(q:sub(2))
      elseif kind == "must_have" then
         if q:sub(2) == "unread" then
            if not query.must_not_have then
               query.must_not_have = {}
            end
            table.insert(query.must_not_have, "read")
         else
            if not query.must_have then
               query.must_have = {}
            end
            table.insert(query.must_have, q:sub(2))
         end
      elseif kind == "must_not_have" then
         if q:sub(2) == "unread" then
            if not query.must_have then
               query.must_have = {}
            end
            table.insert(query.must_have, "read")
         else
            if not query.must_not_have then
               query.must_not_have = {}
            end
            table.insert(query.must_not_have, q:sub(2))
         end
      elseif kind == "limit" then
         query.limit = tonumber(q:sub(2))
      end
   end
   return query
end

return M
