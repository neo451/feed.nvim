local M = {}
local flatdb = require("rss.db")
local db = flatdb("/home/n451/Plugins/rss.nvim/lua/data")
local config = require("rss.config")

local function kv(k, v)
	return string.format("%s: %s", k, v)
end

---@class rss.entry
---@field author string
---@field description string
---@field link string
---@field pubDate string
---@field title string
---@field feed string
---@field tags table<string, boolean>

---@param item rss.entry
---@return table
local function format_item(item)
	local lines = {}
	lines[1] = kv("Title", item.title)
	lines[2] = kv("Date", item.pubDate)
	lines[3] = kv("Author", item.author or item.feed)
	lines[4] = kv("Feed", item.feed)
	lines[5] = kv("Link", item.link)
	lines[6] = ""
	if item["content:encoded"] then
		lines[7] = item["content:encoded"]
	else
		lines[7] = item.description
	end
	return lines
end

---@param lines string[]
---@param buf integer
---@param callback fun(buf: integer)
local function render(lines, buf, callback)
	vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	if callback then
		callback(buf)
	end
	vim.api.nvim_set_current_buf(buf)
	vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
	vim.api.nvim_set_option_value("filetype", "markdown", { buf = buf })
end

---render whole db as expandable tree folder
local function render_tree() end

---@return rss.entry
local function current_entry()
	local row = vim.api.nvim_win_get_cursor(0)[1]
	return db[M.index[row]]
end

local index_actions = {
	leave_index = "<cmd>bd<cr>",
}
local entry_actions = {}

function index_actions.open_browser()
	vim.ui.open(current_entry().link)
end

function index_actions.open_entry()
	M.render_page(current_entry())
end

function index_actions.link_to_clipboard()
	vim.fn.setreg("+", current_entry().link)
end

function index_actions.add_tag()
	local input = vim.fn.input("Tag: ")
	current_entry().tags[input] = true
	db:save()
	M.render_index()
end

function index_actions.remove_tag()
	local input = vim.fn.input("Tag: ")
	current_entry().tags[input] = nil
	db:save()
	M.render_index()
end

function entry_actions.back_to_index()
	vim.api.nvim_set_current_buf(M.buf.index)
end

---@param buf integer
---@param lhs string
---@param rhs string | function
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

local months =
	{ Jan = 1, Feb = 2, Mar = 3, Apr = 4, May = 5, Jun = 6, Jul = 7, Aug = 8, Sep = 9, Oct = 10, Nov = 11, Dec = 12 }

---@param str string
---@return string
local function process_date(str)
	local weekday, day, month, year, time, zone = str:match("([%a]+), (%d+) ([%a]+) (%d+) (%d+:%d+:%d+) ([%+%-]%d+)")
	return (config.date_format):format(year, months[month], day)
end

local function process_title(str)
	if #str < 30 then
		return str .. string.rep(" ", 30 - #str)
	else
		return str:sub(1, 30)
	end
end

---@param tags string[]
---@return string
local function process_tags(tags)
	tags = vim.tbl_keys(tags)
	local buffer = { "(" }
	if #tags == 0 then
		return "()"
	end
	for i, tag in pairs(tags) do
		buffer[#buffer + 1] = tag
		if i ~= #tags then
			buffer[#buffer + 1] = ", "
		end
	end
	buffer[#buffer + 1] = ")"
	return table.concat(buffer, "")
end

-- TODO: justify
---@param title string
---@return string
local function format_title(title, format)
	format = format or "%s %s    %s %s"
	vim.api.nvim_win_get_width(0) -- TODO:
	return string.format(format, process_date(db[title].pubDate), title, db[title].feed, process_tags(db[title].tags))
end

---@param buf integer
local function highlight_page(buf)
	local len = { 6, 5, 7, 5, 5 }
	for i = 0, 4 do
		vim.highlight.range(buf, 1, "Title", { i, 0 }, { i, len[i + 1] })
	end
end

---@param buf integer
local function highlight_index(buf)
	local len = #vim.api.nvim_buf_get_lines(buf, 0, -1, true) -- TODO: api??
	for i = 0, len do
		vim.highlight.range(buf, 1, "Title", { i, 0 }, { i, 10 })
	end
end

---@alias filterFunc fun(item: rss.entry): boolean

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
---@param cond filterFunc?
function M.render_index(cond)
	cond = cond or function()
		return true
	end
	local to_render = filter(db.titles, cond)
	M.index = vim.deepcopy(to_render, true) -- HACK:
	for i, title in ipairs(to_render) do
		to_render[i] = format_title(tostring(title))
	end
	render(to_render, M.buf.index, highlight_index)
end

---@param item rss.entry
function M.render_page(item)
	render(format_item(item), M.buf.page, highlight_page)
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
					M.render_page(db[selection[1]])
				end)
				return true
			end,
			sorter = conf.generic_sorter(opts), -- TODO: sort by date?
		})
		:find()
end

function M.setup()
	M.buf = {
		index = vim.api.nvim_create_buf(false, true),
		page = vim.api.nvim_create_buf(false, true),
	}
	for rhs, lhs in pairs(config.index_keymaps) do
		push_keymap(M.buf.index, lhs, index_actions[rhs])
	end
	for rhs, lhs in pairs(config.entry_keymaps) do
		push_keymap(M.buf.page, lhs, entry_actions[rhs])
	end
end

return M
