-- local fstr2 = io.open("/home/n451/Plugins/rss.nvim/lua/html.html", "r"):read("*a")
local M = {}
-- TODO: handle nested tags
-- TODO: handle list

local nested =
	[[<p> For me the most exciting thing about this is its ability to visualize what the Zig Build System is up to after you run <code>zig build</code>. Before this feature was even merged into master branch, it led to discovery, diagnosis, and <a href="https://github.com/ziglang/zig/commit/389181f6be8810b5cd432e236a962229257a5b59">resolution</a> of a subtle bug that has hidden in Zig's standard library child process spawning code for years. Not included in this blog post: a rant about how much I hate the fork() API. </p>]]

local n2 =
	[[<pre><code class="language-c">#include "zp.h" #include &lt;string.h&gt; #include &lt;unistd.h&gt; int main(int argc,
    char **argv) { zp_node root_node = zp_init(); const char *task_name = "making orange juice"; zp_node sub_node =
    zp_start(root_node, task_name, strlen(task_name), 5); for (int i = 0; i &lt; 5; i += 1) { zp_complete_one(sub_node);
    sleep(1); } zp_end(sub_node); zp_end(root_node); }</code></pre>]]

local function get_root(str)
	local parser = vim.treesitter.get_string_parser(str, "html")
	return parser:parse()[1]:root()
end

local ele_query = vim.treesitter.query.parse("html", "(element) @ele")

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

--- handle &lt, &gt
local function lt_gt(src)
	src = src:gsub("&lt;", "<")
	src = src:gsub("&gt;", ">")
	return src
end

local function get_text(node, html)
	return vim.treesitter.get_node_text(node, html)
end

---
---@param node TSNode
---@param html string
---@return string?, string?
---TODO: wrong...
local function tag_info(node, html)
	print(get_text(node:child(1), html))
	-- print(node:child(0):child_count())
	if node:child(0):child_count() == 3 then
		if vim.treesitter.get_node_text(node:child(0), html) == "code" then
			return "short_code"
		end
		return vim.treesitter.get_node_text(node:child(0):child(1), html)
		-- return "short_code"
	elseif node:child(0):child_count() == 4 then
		print(vim.treesitter.get_node_text(node:child(0):child(1), html))
		return vim.treesitter.get_node_text(node:child(0):child(1), html),
			vim.treesitter.get_node_text(node:child(0):child(2):child(2), html)
	end
end

local function trans_node(node, html)
	local buffer = {}
	local n_child = node:named_child_count()
	print(get_text(node, html))
	-- print(n_child)
	if n_child == 3 then
		local T, additional = tag_info(node, html)
		local text = vim.treesitter.get_node_text(node:named_child(1), html)
		-- print(lt_gt(text), additional)
		print(text)
		return trans(T, text, additional)
	end
	for i = 1, n_child - 2 do
		local child = node:named_child(i)
		local child_type = child:type()
		if child_type == "text" then
			buffer[#buffer + 1] = vim.treesitter.get_node_text(child, html)
		else
			buffer[#buffer + 1] = trans_node(child, html)
		end
	end
	return table.concat(buffer, " ")
end

---@param html string
---@return table
function M.to_md(html)
	local lines = {}
	html = html:gsub("<pre>", "")
	html = html:gsub("</pre>", "")
	html = lt_gt(html)
	for node in get_root(html):iter_children() do
		-- for i, node in ele_query:iter_captures(get_root(html), html, 0, -1) do
		lines[#lines + 1] = trans_node(node, html)
	end
	return lines
end

local n3 = [[<h1>sdada</h1>]]

local list = [[
<ol>
  <li><a href="https://gist.github.com/christianparpart/d8a62cc1ab659194337d73e399004036">Start sync sequence</a>. This
    makes high framerate terminals not blink rapidly.</li>
  <li>Clear previous update by moving cursor up times the number of newlines outputted last time, and then a clear to
    end of screen escape sequence.</li>
  <li>Recursively walk the tree of nodes, which which is now possible since we have computed children and sibling edges,
    outputting tree-drawing sequences, node names, and counting newlines.</li>
  <li>End sync sequence.</li>
</ol>
]]

-- M.to_md(nested)
-- pp(M.to_md(nested))

return M
