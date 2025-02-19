local date = require("feed.parser.date")

local M = {}

---@class feed.query
---@field after? integer #@
---@field before? integer #@
---@field must_have? string[] #+
---@field must_not_have? string[] #-
---@field feed? vim.regex #=
---@field not_feed? vim.regex #~
---@field limit? number ##
---@field re? vim.regex[]

---wrapper arround vim.regex, ! is inverse, respects vim.o.ignorecase
---@param str string
local function build_regex(str)
   local pattern
   if str:sub(0, 1) == "!" then
      pattern = [[^\(.*]] .. vim.fn.escape(str:sub(2), "\\") .. [[.*\)\@!.*]]
   else
      pattern = str
   end
   if vim.o.ignorecase then
      pattern = pattern .. "\\c"
   else
      pattern = pattern .. "\\C"
   end
   return vim.regex(pattern)
end

M._build_regex = build_regex

---@param str string
---@return feed.query
function M.parse_query(str)
   str = str:gsub("+unread", "-read"):gsub("-unread", "+read")
   local query = {}
   for q in vim.gsplit(str, " ") do
      local kind = q:sub(1, 1)
      if kind == "@" then
         query.after, query.before = date.parse_filter(q)
      elseif kind == "#" then
         query.limit = tonumber(q:sub(2))
      elseif kind == "+" then
         if not query.must_have then
            query.must_have = {}
         end
         table.insert(query.must_have, q:sub(2))
      elseif kind == "-" then
         if not query.must_not_have then
            query.must_not_have = {}
         end
         table.insert(query.must_not_have, q:sub(2))
      elseif kind == "=" then
         query.feed = build_regex(q:sub(2))
      elseif kind == "~" then
         query.not_feed = build_regex(q:sub(2))
      else
         if not query.re then
            query.re = {}
         end
         table.insert(query.re, build_regex(q))
      end
   end
   return query
end

return M
