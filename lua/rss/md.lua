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

---@param ast xml.ast
local function to_md(ast)
	if vim.islist(ast) then
		error("only one root element is allowed")
	end
	local buffer = {}
	for k, v in pairs(ast) do
		if vim.islist(v) then
			local buf = {}
			for _, vv in ipairs(v) do
				if type(vv) == "string" then
					table.insert(buf, vv)
				else
					table.insert(buf, to_md(vv))
				end
			end
			v = table.concat(buf, " ")
		end
		table.insert(buffer, transforms[k]:format(v))
	end
	return table.concat(buffer, " ")
end

return to_md
