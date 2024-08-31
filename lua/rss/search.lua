local lpeg = vim.lpeg
local ut = require("rss.utils")
local config = require("rss.config")
local date = require("rss.date")

local M = {
	search_filter = config.search.filter,
	---"List of the entries currently on display."
	---@type rss.entry[]
	entries = {},
	--- TODO: "List of the entries currently on display."
	filter_history = {},
	---@type integer
	last_update = 0,
	---List of functions to run immediately following a search buffer update.
	---@type function[]
	update_hook = config.search.update_hook, -- TODO:
	sort_order = config.search.sort_order,  -- TODO:
}

---@class rss.query
---@field after rss.date #@
---@field before rss.date #@
---@field must_have rss.pattern #+
---@field must_not_have rss.pattern #-
---@field matches rss.pattern #~ =
---@field not_matches rss.pattern #!
---@field feeds string
---@field not_feeds string
---@field limit number ##
---@field re rss.pattern #=

---@alias rss.pattern vim.regex | vim.lpeg.Pattern | string # regex

local filter_symbols = {
	["+"] = "must_have",
	["-"] = "must_not_have",
	["="] = "re",
	["@"] = "date",
}

---@param str string
---@return rss.query
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

--- TODO: see lpeg.re.lua

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

---@param entries rss.entry[]
---@param query rss.query
---@return rss.entry[]
local function filter(entries, query)
end

return M
