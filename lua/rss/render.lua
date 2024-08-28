local M = { state = {}, index = nil }
local flatdb = require("rss.db")
local config = require("rss.config")
local db = flatdb(config.db_dir)
local ut = require("rss.utils")
local date = require("rss.date")

local function kv(k, v)
	return string.format("%s: %s", k, v)
end

---@class rss.render
---@field state table<string, boolean>
---@field curent_index integer
---@field current_entry fun(): table<string, any>
---@field render_entry fun(row: integer)

---@class rss.entry
---@field author string
---@field description string
---@field link string
---@field pubDate string
---@field title string
---@field feed string
---@field tags table<string, boolean>

---@param entry rss.entry
---@return table
local function show_entry(entry)
	local lines = {}
	lines[1] = kv("Title", entry.title)
	lines[2] = kv("Date", entry.pubDate)
	lines[3] = kv("Author", entry.author or entry.feed)
	lines[4] = kv("Feed", entry.feed)
	lines[5] = kv("Link", entry.link)
	lines[6] = ""
	if entry["content:encoded"] then
		lines[7] = entry["content:encoded"]
	else
		lines[7] = entry.description
	end
	return lines
end

---@param lines string[]
---@param buf integer
---@param callback fun(buf: integer)
---@param display boolean
local function render(lines, buf, callback, display)
	vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	if callback then
		callback(buf)
	end
	vim.api.nvim_set_current_buf(buf)

	vim.api.nvim_set_option_value("conceallevel", 0, { win = vim.api.nvim_get_current_win() })
	-- vim.api.nvim_set_option_value("colorscheme", config.colorscheme, { win = vim.api.nvim_get_current_win() })
	config.og_colorscheme = vim.cmd.colorscheme()
	vim.cmd.colorscheme(config.colorscheme)
	vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
	vim.api.nvim_set_option_value("filetype", "markdown", { buf = buf })
end

---@return rss.entry
function M.current_entry()
	local row = vim.api.nvim_win_get_cursor(0)[1]
	return db[M.index[row]]
end

---@param title string
---@return string
local function entry_name(title, format)
	local entry = db[title]
	format = format or "%s %s %s %s"
	-- vim.api.nvim_win_get_width(0) -- TODO:
	-- print(ut.str_len(title))
	-- print(title)
	return string.format(
		format,
		tostring(date.new_from_entry(entry.pubDate)),
		ut.format_title(entry.title, config.max_title_length),
		entry.feed,
		ut.format_tags(entry.tags)
	)
end

---render whole db as flat list
function M.render_index()
	M.index = vim.deepcopy(db.titles, true) -- HACK:
	local to_render = {}
	for i, title in ipairs(db.titles) do
		to_render[i] = entry_name(title)
	end
	render(to_render, M.buf.index, ut.highlight_index, true)
end

---@param index integer
function M.render_entry(index)
	local entry = db[M.index[index]]
	-- local prev = (index > 1) and db[M.index[index - 1]] or nil
	-- local next = db[M.index[index + 1]]
	-- render(format_entry(prev), M.buf.entry[1], ut.highlight_entry, false)
	render(show_entry(entry), M.buf.entry[2], ut.highlight_entry, true)
	-- render(format_entry(next), M.buf.entry[3], ut.highlight_entry, false)
end

---TODO: fuzzy finding in filter search ?  #fuzz #filter

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
					render(show_entry(db[selection[1]]), M.buf.entry[2], ut.highlight_entry, true)
				end)
				return true
			end,
			sorter = conf.generic_sorter(opts), -- TODO: sort by date?
		})
		:find()
end

return M
