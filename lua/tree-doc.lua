local fstr2 = io.open("/home/n451/Plugins/rss.nvim/lua/html.html", "r"):read("*a")

local function get_root(str)
	local parser = vim.treesitter.get_string_parser(str, "html")
	return parser:parse()[1]:root()
end

local ele_query = vim.treesitter.query.parse("html", "(element) @ele")

local name_query = vim.treesitter.query.parse("html", "(element (start_tag (tag_name) @t))")
local text_query = vim.treesitter.query.parse("html", "(element (text) @t)")

local link_query = vim.treesitter.query.parse("html", "(quoted_attribute_value (attribute_value) @a)")

local function get_one(query, node)
	return query:iter_captures(node, fstr, 0, -1)()
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

local function get_dat_md(fstr)
	local lines = {}
	for i, node in ele_query:iter_captures(get_root(fstr), fstr, 0, -1) do
		local _, type_node = get_one(name_query, node)
		local _, text_node = get_one(text_query, node)
		local T = vim.treesitter.get_node_text(type_node, fstr)
		local oktext, text = pcall(vim.treesitter.get_node_text, text_node, fstr)
		if T == "a" then
			local _, link_node = get_one(link_query, node)
			local link = vim.treesitter.get_node_text(link_node, fstr)
			lines[#lines + 1] = (trans(T, text, link))
		elseif T == "code" then
			local _, link_node = get_one(link_query, node)
			local oklang, lang = pcall(vim.treesitter.get_node_text, link_node, fstr)
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
	-- return table.concat(lines, "\n")
	return lines
end

-- TODO: handle nested tags
local function render(lines)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	-- for i = 0, 4 do
	-- 	vim.highlight.range(buf, 1, "Title", { i, 0 }, { i, len[i + 1] })
	-- end
	vim.api.nvim_set_option_value("filetype", "markdown", { buf = buf })
	vim.api.nvim_set_current_buf(buf)
	-- TODO: push keymaps like q to buffer
end

render((get_dat_md(fstr2)))
