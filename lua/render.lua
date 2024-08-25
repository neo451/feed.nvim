local M = {}
local flatdb = require("db")
local db = flatdb("./db")

local function kv(k, v)
	return string.format("%s: %s", k, v)
end

---@class item
---@field author string
---@field description string
---@field link string
---@field pubDate string
---@field title string
---@field feed string

---@param item item
---@return table
local function render_item(item)
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

local len = { 6, 5, 7, 5, 5 }

local function render(lines)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	for i = 0, 4 do
		vim.highlight.range(buf, 1, "Title", { i, 0 }, { i, len[i + 1] })
	end
	vim.api.nvim_set_current_buf(buf)
	-- TODO: push keymaps like q to buffer
end

---render whole db as expandable tree folder
local function render_tree() end

---render whole db as flat list
local function render_flat() end

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
						render(render_item(db[selection[1]]))
					end)
					return true
				end,
				sorter = conf.generic_sorter(opts), -- TODO: sort by date?
			})
			:find()
end

return M
