local M = {
	state = {},
	index = nil,
}

-- local flatdb = require("rss.db")
local flatdb = require("rss._db")
local config = require("rss.config")
local ut = require("rss.utils")
local db = flatdb(config.db_dir)
local date = require("rss.date")

---@class rss.render
---@field state table<string, boolean>
---@field curent_index integer
---@field current_entry fun(): table<string, any>
---@field show_entry fun(row: integer)

---@class rss.entry
---@field author string
---@field description string
---@field link string
---@field pubDate integer
---@field title string
---@field feed string
---@field tags table<string, boolean>
---@field id string

function M.get_entry(index)
	return db[M.index[index]]
end

---@param buf integer
local function set_options(buf)
	for key, value in pairs(config.win_options) do
		vim.api.nvim_set_option_value(key, value, { win = vim.api.nvim_get_current_win() })
	end
	for key, value in pairs(config.buf_options) do
		vim.api.nvim_set_option_value(key, value, { buf = buf })
	end
	config.og_colorscheme = vim.cmd.colorscheme()
	vim.cmd.colorscheme(config.colorscheme)
end

---@param lines string[]
---@param buf integer
---@param callback fun(buf: integer)
function M.show(lines, buf, callback)
	vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_set_current_buf(buf)
	if callback then
		callback(buf)
	end
	set_options(buf)
end

---@param entry rss.entry
---@return string
local function entry_name(entry)
	local format = "%s %s %s %s"
	-- vim.api.nvim_win_get_width(0) -- TODO: use this or related autocmd to truncate title
	return string.format(
		format,
		date.new_from_int(entry.pubDate),
		-- tostring(date.new_from_entry(entry.pubDate)),
		ut.format_title(entry.title, config.max_title_length),
		entry.feed,
		ut.format_tags(entry.tags)
	)
end

---render whole db as flat list
function M.show_index()
	-- M.index = vim.deepcopy(db.index, true) -- HACK:
	local lines = {}
	lines[1] = M.show_hint()
	for i, entry in ipairs(db.index) do
		lines[i + 1] = entry_name(entry)
	end
	M.show(lines, M.buf.index, ut.highlight_index)
end

---@param index integer
function M.show_entry(index)
	local entry = db[M.index[index]]
	M.show(ut.format_entry(entry), M.buf.entry[2], ut.highlight_entry)
	entry.tags.unread = nil
	db:save()
end

---@return string
function M.show_hint()
	return "Hint: <M-CR> open in split | <CR> open | + add_tag | - remove | ? help"
end

return M
