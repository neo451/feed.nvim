---@alias xml.ast table<string, string | table>

local transforms = {
	h1 = "# %s",
	h2 = "## %s",
	h3 = "### %s",
	h4 = "#### %s",
	h5 = "##### %s",
	p = "  %s",
	a = "[%s](%s)",
	-- code = [[```%s %s ```]],
	code = "`%s`",
	pre = "",
}

local function is_array(tbl)
	return type(tbl) == "table" and (#tbl > 0 or next(tbl) == nil)
end

---@param ast xml.ast
local function to_md(ast)
	if is_array(ast) then
		error("only one root element is allowed")
	end
	local buffer = {}
	for k, v in pairs(ast) do
		if is_array(v) then
			local _buffer = {}
			for _, vv in ipairs(v) do
				if type(vv) == "string" then
					table.insert(_buffer, vv)
				else
					table.insert(_buffer, to_md(vv))
				end
			end
			v = table.concat(_buffer, " ")
		end
		table.insert(buffer, transforms[k]:format(v))
	end
	return table.concat(buffer, " ")
end

return to_md
