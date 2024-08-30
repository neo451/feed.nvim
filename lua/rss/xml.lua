local lpeg = vim.lpeg

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

local text = (1 - S("<")) ^ 1

local name = (alnum - punct) ^ 1 / id
local quoted_string = P('"') * ((1 - P('"')) ^ 0 / id) * P('"')
local kv = ws * name * "=" * quoted_string * ws / function(k, v)
	return k, v
end

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

local grammar = {
	[1] = "element",
	content = ws * (text + (element ^ 0)) * ws / function(...)
		if select("#", ...) == 1 then
			return ...
		end
		local acc = {}
		for _, v in pairs({ ... }) do
			acc = vim.tbl_deep_extend("keep", acc, v)
		end
		return acc
	end,
	element = ws * start_tag * content * end_tag / function(T, ele_or_text, _)
		return { [T] = ele_or_text }
	end * ws,
}

grammar = Ct(C(grammar))

local function parse(s)
	return grammar:match(s)[2]
end

return parse
