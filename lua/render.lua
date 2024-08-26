local M = {}
local flatdb = require("db")
local db = flatdb("/home/n451/Plugins/rss.nvim/lua/data")

local function kv(k, v)
	return string.format("%s: %s", k, v)
end

local bufs = {
	index = nil,
}

---@class item
---@field author string
---@field description string
---@field link string
---@field pubDate string
---@field title string
---@field feed string

---@param item item
---@return table
local function format_item(item)
	local lines = {}
	lines[1] = kv("Title", item.title)
	lines[2] = kv("Date", item.pubDate)
	lines[3] = kv("Author", item.author or item.feed)
	lines[4] = kv("Feed", item.feed)
	lines[5] = kv("Link", item.link)
	lines[6] = ""
	lines[7] = item.description
	return lines
end

---@param lines string[]
---@param buf integer
---@param callback fun(buf: integer)
local function render(lines, buf, callback)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	if callback then
		callback(buf)
	end
	vim.api.nvim_set_current_buf(buf)
	vim.api.nvim_set_option_value("filetype", "markdown", { buf = buf })
end

---render whole db as expandable tree folder
local function render_tree() end

local function open_browser()
	local row = vim.api.nvim_win_get_cursor(0)[1]
	local link = db[M.index[row]].link
	vim.ui.open(link)
end

local function open_entry()
	local row = vim.api.nvim_win_get_cursor(0)[1]
	print(M.index[row])
	local item = db[M.index[row]]
	local buf = vim.api.nvim_create_buf(false, true)
	M.render_page(item, buf)
end

local function link_to_clipboard()
	local row = vim.api.nvim_win_get_cursor(0)[1]
	local link = db[M.index[row]].link
	vim.fn.setreg("+", link)
end

local function add_tag()
	local row = vim.api.nvim_win_get_cursor(0)[1]
	local title = M.index[row]
	local tags = db[title].tags
	local new_tag = vim.fn.input("Tag: ")
	tags[#tags + 1] = new_tag
end

local function push_keymap(buf, lhs, rhs)
	if type(rhs) == "string" then
		vim.api.nvim_buf_set_keymap(buf, "n", lhs, rhs, { noremap = true, silent = true })
	else
		vim.api.nvim_buf_set_keymap(buf, "n", lhs, "", {
			noremap = true,
			silent = true,
			callback = rhs,
		})
	end
end

local function index_keymaps(buf)
	push_keymap(buf, "<CR>", open_entry)
	push_keymap(buf, "b", open_browser)
	push_keymap(buf, "y", link_to_clipboard)
	push_keymap(buf, "q", "<cmd>bd<cr>")
	push_keymap(buf, "+", add_tag)
end

local function page_keymaps(buf)
	push_keymap(buf, "q", M.render_index)
end

local months =
	{ Jan = 1, Feb = 2, Mar = 3, Apr = 4, May = 5, Jun = 6, Jul = 7, Aug = 8, Sep = 9, Oct = 10, Nov = 11, Dec = 12 }

local function process_date(str)
	local weekday, day, month, year, time, zone = str:match("([%a]+), (%d+) ([%a]+) (%d+) (%d+:%d+:%d+) ([%+%-]%d+)")
	return ("%s-%02d-%02d"):format(year, months[month], day)
end

local function process_title(str)
	if #str < 30 then
		return str .. string.rep(" ", 30 - #str)
	else
		return str:sub(1, 30)
	end
end

local function process_tags(tags)
	local buffer = { "(" }
	if tags == nil then
		return ""
	end
	for _, tag in pairs(tags) do
		buffer[#buffer + 1] = tag
		buffer[#buffer + 1] = ", "
	end
	buffer[#buffer + 1] = ")"
	return table.concat(buffer, "")
end

local function format_title(title)
	vim.api.nvim_win_get_width(0) -- TODO:
	return string.format(
		"%s %s    %s %s",
		process_date(db[title].pubDate),
		title,
		db[title].feed,
		process_tags(db[title].tags)
	)
end

local function highlight_page(buf)
	local len = { 6, 5, 7, 5, 5 }
	for i = 0, 4 do
		vim.highlight.range(buf, 1, "Title", { i, 0 }, { i, len[i + 1] })
	end
end

local function highlight_index(buf)
	local len = #vim.api.nvim_buf_get_lines(buf, 0, -1, true) -- TODO: api??
	for i = 0, len do
		vim.highlight.range(buf, 1, "Title", { i, 0 }, { i, 10 })
	end
end

---@alias filterFunc fun(item: item): boolean

local function has_tag(title, tag)
	return db[title][tag] ~= nil
end

local function filter(list, cond)
	local filtered = {}
	for _, title in ipairs(list) do
		if cond(list) then
			filtered[#filtered + 1] = title
		end
	end
	return filtered
end

M.index = nil

---render whole db as flat list
---@param cond filterFunc
function M.render_index(cond)
	cond = cond or function()
		return true
	end
	if not bufs.index then
		bufs.index = vim.api.nvim_create_buf(false, true)
	end
	local to_render = filter(db.titles, cond)
	M.index = vim.deepcopy(to_render, true) -- HACK:
	for i, title in ipairs(to_render) do
		to_render[i] = format_title(title)
	end
	render(to_render, bufs.index, highlight_index)
	index_keymaps(bufs.index)
end

---@param item item
---@param buf integer
function M.render_page(item, buf)
	render(format_item(item), buf, highlight_page)
	page_keymaps(buf)
end

---render whole db in telescope
function M.render_telescope(opts)
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	opts = opts or {}

	pickers
		.new(opts, {
			prompt_title = "Feeds",
			finder = finders.new_table({
				results = db.titles,
			}),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					local buf = vim.api.nvim_create_buf(false, true)
					M.render_page(db[selection[1]], buf)
				end)
				return true
			end,
			sorter = conf.generic_sorter(opts), -- TODO: sort by date?
		})
		:find()
end

-- vim.api.nvim_get_win_info

return M
