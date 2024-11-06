local date = require "feed.date"

local M = {}

---@class feed.query
---@field after? feed.date #@
---@field before? feed.date #@
---@field must_have? string[] #+
---@field must_not_have? string[] #-
---@field feeds? string #=
---@field limit? number ##
---@field re? feed.pattern[]

---TODO: !

---@alias feed.pattern vim.regex | vim.lpeg.Pattern | string # regex

local filter_symbols = {
   ["+"] = "must_have",
   ["-"] = "must_not_have",
   ["@"] = "date",
   ["#"] = "limit",
}

---@param str string
---@return feed.query
function M.parse_query(str)
   local query = {}
   for q in vim.gsplit(str, " ") do
      local kind = filter_symbols[q:sub(1, 1)] or "re"
      if kind == "date" then
         query.after, query.before = date.new_from.filter(q)
      elseif kind == "re" then
         if not query.re then
            query.re = {}
         end
         table.insert(query.re, vim.regex(q .. "\\c"))
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

local function check(v, query)
   local res = true
   if query.re then
      for _, reg in ipairs(query.re) do
         if not reg:match_str(v.title) then
            return false
         end
      end
   end
   if query.after then
      if v.time < query.after or v.time > query.before then
         return false
      end
   end
   if query.must_have then
      for _, t in ipairs(query.must_have) do
         if not v.tags[t] then
            return false
         end
      end
   end
   if query.must_not_have then
      for _, t in ipairs(query.must_not_have) do
         if v.tags[t] then
            return false
         end
      end
   end
   return res
end

--- tag read should be default for empty tags

---@param entries feed.entry[]
---@param query feed.query
---@return feed.entry[]
function M.filter(entries, query)
   local tbl = vim.deepcopy(entries, true)
   local res = {}
   for i, v in pairs(tbl) do
      if type(v) == "table" then
         if query.limit and i > query.limit then
            break
         end
         if check(v, query) then
            res[#res + 1] = v
         end
      end
   end
   table.sort(res, function(a, b)
      assert(a.time, ("no timestamp for %s"):format(vim.inspect(a)))
      assert(b.time, ("no timestamp for %s"):format(vim.inspect(b)))
      return a.time > b.time
   end)
   return res
end

return M
