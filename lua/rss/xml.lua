local lpeg = vim.lpeg
local M = {}

---TODO: entities
---TODO: proper naming to spec
---TODO: test opml parsing
---TODO: id capture is weird, read more docs

lpeg.locale(lpeg)
local P = lpeg.P
local V = lpeg.V
local S = lpeg.S
local Ct = lpeg.Ct
local C = lpeg.C
local alnum = lpeg.alnum
local punct = lpeg.punct

local ws = S(" \t\n\r") ^ 0

local id = function(a)
	return a
end

local text = (1 - P("<")) ^ 1

local name = (alnum - punct) ^ 1 / id -- TODO: check spec
local quoted_string = P('"') * ((1 - P('"')) ^ 0 / id) * P('"')
local kv = ws * name * "=" * quoted_string * ws

local end_tag = P("</") * name * P(">") / id

local start_tag = P("<")
		* name
		* kv ^ 0
		* P(">")
		/ function(T, ...)
			local tab = { ... }
			if #tab == 0 then
				return T
			end
			local t = {}
			t[T] = {}
			for i = 1, select("#", ...) do
				local k, v = select(i, ...)
				t[T][k] = v
			end
			return t
		end

local element = V("element")
local content = V("content")

local CData = (1 - P("]]>")) ^ 0 / id
local CDSect = "<![CDATA[" * CData * "]]>"
local XMLDecl = P([[<?xml version="1.0" encoding="UTF-8"?>]]) --HACK:
-- "<?xml" * text * "?>"

local grammar = {
	[1] = "document",

	document = ws * XMLDecl ^ -1 * ws * element ^ 1 * ws / function(...)
		if select("#", ...) == 1 then
			return ...
		end
		return { ... }
	end,
	content = ws * (text + CDSect + (element ^ 0)) * ws / function(...)
		if select("#", ...) == 1 then
			return ...
		end
		local acc = {}
		local last_key = nil
		for _, v in pairs({ ... }) do
			local key = vim.tbl_keys(v)[1]
			if key == last_key then
				if type(acc[key]) ~= "table" then
					acc[key] = { acc[key] }
				end
				for k, val in pairs(v) do
					table.insert(acc[key], val)
				end
			else
				acc = vim.tbl_deep_extend("keep", acc, v)
			end
			last_key = key
		end
		return acc
	end,
	element = ws
			* start_tag
			* content
			* end_tag
			/ function(T, ele_or_text, _)
				if type(T) == "table" then
					if type(ele_or_text) == "table" then
						return vim.tbl_extend("keep", T, ele_or_text)
					else
						-- TODO: possible?? if ele_or_text then end
						return T
					end
				end
				return { [T] = ele_or_text }
			end
			* ws,
}

function M.parse(s)
	return Ct(C(grammar)):match(s)[2]
end

return M
