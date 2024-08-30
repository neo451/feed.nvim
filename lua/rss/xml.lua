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
local text = (1 - P("<")) ^ 1

local name = C((alnum - punct) ^ 1) -- TODO: check spec
local quoted_string = P('"') * C((1 - P('"')) ^ 0) * P('"')
local kv = ws * name * "=" * quoted_string * ws

local end_tag = P("</") * name * P(">")

local function parse_start_tag(T, ...)
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

local function parse_document(...)
	if select("#", ...) == 1 then
		return ...
	end
	return { ... }
end

local function parse_content(...)
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
			for _, val in pairs(v) do
				table.insert(acc[key], val)
			end
		else
			acc = vim.tbl_deep_extend("keep", acc, v)
		end
		last_key = key
	end
	return acc
end

local function parse_element(T, ele_or_text, _)
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

local start_tag = P("<") * name * kv ^ 0 * P(">") / parse_start_tag

local CData = C((1 - P("]]>")) ^ 0)
local CDSect = "<![CDATA[" * CData * "]]>"
local XMLDecl = P([[<?xml version="1.0" encoding="UTF-8"?>]]) --HACK:

local element = V("element")
local content = V("content")
local grammar = {
	[1] = "document",
	document = ws * XMLDecl ^ -1 * ws * element ^ 1 * ws / parse_document,
	content = ws * (text + CDSect + (element ^ 0)) * ws / parse_content,
	element = ws * start_tag * content * end_tag / parse_element * ws,
}

---@param s string
---@return table
function M.parse(s)
	return Ct(C(grammar)):match(s)[2]
end

return M
