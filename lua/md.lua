-- local fstr2 = io.open("/home/n451/Plugins/rss.nvim/lua/html.html", "r"):read("*a")
local M = {}
-- TODO: handle nested tags

local function get_root(str)
	local parser = vim.treesitter.get_string_parser(str, "html")
	return parser:parse()[1]:root()
end

local ele_query = vim.treesitter.query.parse("html", "(element) @ele")

local name_query = vim.treesitter.query.parse("html", "(element (start_tag (tag_name) @t))")
local text_query = vim.treesitter.query.parse("html", "(element (text) @t)")

local link_query = vim.treesitter.query.parse("html", "(quoted_attribute_value (attribute_value) @a)")

local function get_one(query, node, str)
	return query:iter_captures(node, str, 0, -1)()
end

local transforms = {
	h1 = "# %s",
	h2 = "## %s",
	h3 = "### %s",
	h4 = "#### %s",
	h5 = "##### %s",
	p = "  %s",
	a = "[%s](%s)",
	code = [[```%s %s ```]],
	short_code = "`%s`",
	pre = "",
}

local function trans(type, text, link)
	if transforms[type] then
		return transforms[type]:format(text, link)
	else
		-- print(type, text)
	end
end

---@param html string
---@return table
function M.to_md(html)
	local lines = {}
	for i, node in ele_query:iter_captures(get_root(html), html, 0, -1) do
		local _, type_node = get_one(name_query, node, html)
		local _, text_node = get_one(text_query, node, html)
		local T = vim.treesitter.get_node_text(type_node, html)
		local oktext, text = pcall(vim.treesitter.get_node_text, text_node, html)
		if T == "a" then
			local _, link_node = get_one(link_query, node, html)
			local link = vim.treesitter.get_node_text(link_node, html)
			lines[#lines + 1] = (trans(T, text, link))
		elseif T == "code" then
			local _, link_node = get_one(link_query, node, html)
			local oklang, lang = pcall(vim.treesitter.get_node_text, link_node, html)
			if oklang then
				lang = lang:sub(10, #lang) --HACK:
				lines[#lines + 1] = "```" .. lang
				lines[#lines + 1] = text
				lines[#lines + 1] = "```"
			else
				lines[#lines + 1] = trans("short_code", text)
			end
		elseif T == "pre" then
		else
			lines[#lines + 1] = trans(T, text)
		end
	end
	return lines
end

return M
