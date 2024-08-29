local M = { state = {}, index = nil }
local flatdb = require("rss.db")
local config = require("rss.config")
local ut = require("rss.utils")
local db = flatdb(config.db_dir)

---@class rss.render
---@field state table<string, boolean>
---@field curent_index integer
---@field current_entry fun(): table<string, any>
---@field show_entry fun(row: integer)

---@class rss.entry
---@field author string
---@field description string
---@field link string
---@field pubDate string
---@field title string
---@field feed string
---@field tags table<string, boolean>

function M.get_entry(index)
	return db[M.index[index]]
end

---@param config rss.config
local function set_options(config, buf)
	for opt_name, value in pairs(config.win_options) do
		vim.api.nvim_set_option_value(opt_name, value, { win = vim.api.nvim_get_current_win() })
	end
	for opt_name, value in pairs(config.buf_options) do
		vim.api.nvim_set_option_value(opt_name, value, { buf = buf })
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
	set_options(config, buf)
end

---render whole db as flat list
function M.show_index()
	M.index = vim.deepcopy(db.titles, true) -- HACK:
	local to_render = {}
	to_render[1] = M.show_hint()
	for i, title in ipairs(db.titles) do
		to_render[i + 1] = tostring(db[title])
	end
	M.show(to_render, M.buf.index, ut.highlight_index)
end

---@param index integer
function M.show_entry(index)
	local entry = db[M.index[index]]
	M.show(ut.format_entry(entry), M.buf.entry[2], ut.highlight_entry)
end

function M.show_hint()
	return "Hint: <M-CR> open in split | <CR> open | + add_tag | - remove | ? help"
end

return M
