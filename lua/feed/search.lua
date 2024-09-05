local config = require "feed.config"
local date = require "feed.date"

local M = {
   search_filter = config.search.filter,
   ---"List of the entries currently on display."
   ---@type feed.entry[]
   entries = {},
   --- TODO: "List of the entries currently on display."
   filter_history = {},
   ---@type integer
   last_update = 0,
   ---List of functions to run immediately following a search buffer update.
   ---@type function[]
   update_hook = config.search.update_hook, -- TODO:
   sort_order = config.search.sort_order,   -- TODO:
}

---@class feed.query
---@field after feed.date #@
---@field before feed.date #@
---@field must_have feed.pattern #+
---@field must_not_have feed.pattern #-
---@field matches feed.pattern #~ =
---@field not_matches feed.pattern #!
---@field feeds string
---@field not_feeds string
---@field limit number ##
---@field re feed.pattern #=

---@alias feed.pattern vim.regex | vim.lpeg.Pattern | string # regex

local filter_symbols = {
   ["+"] = "must_have",
   ["-"] = "must_not_have",
   ["="] = "re",
   ["@"] = "date",
}

---@param str string
---@return feed.query
function M.parse_query(str)
   local query = { must_have = {}, must_not_have = {} }
   for q in vim.gsplit(str, " ") do
      -- print(q)
      local kind = filter_symbols[q:sub(1, 1)]
      if kind == "date" then
         query.after, query.before = date.parse_date_filter(q)
      elseif kind == "must_have" then
         table.insert(query.must_have, q:sub(2))
      elseif kind == "must_not_have" then
         table.insert(query.must_not_have, q:sub(2))
      end
   end
   return query
end

---check if a valid pattern
---@param str any
---@return boolean
function M.valid_pattern(str)
   if vim.lpeg.type(str) == "pattern" then
      return true
   else
      local ok, obj = pcall(vim.regex, str)
      if ok and tostring(obj) == "<regex>" then
         return true
      end
   end
   return false
end

---@param entries feed.entry[]
---@param query feed.query
---@return feed.entry[]
local function filter(entries, query) end

return M