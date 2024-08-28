--- Default configuration.
--- Provides fallback values not specified in the user config.

local default = {
	date_format = "%s-%02d-%02d",
	keymaps = {},
	---@type table<string, string | function>
	index_keymaps = {
		open_entry = "<CR>",
		open_split = "<M-CR>",
		open_browser = "b",
		open_w3m = "w",
		link_to_clipboard = "y",
		leave_index = "q",
		add_tag = "+",
		remove_tag = "-",
	},
	entry_keymaps = {
		back_to_index = "q",
		next_entry = "}",
		prev_entry = "{",
	},
	search = {
		sort_order = "descending",
		update_hook = {},
	},
	split = "13split",
	-- max_title_len = 50,
	db_dir = vim.fn.expand("~/.rss.nvim"),
}

local M = {}

setmetatable(M, {
	__index = function(self, key)
		local config = rawget(self, "config")
		if config then
			return config[key]
		end
		return default[key]
	end,
})

-- local function prepare_db()
if vim.fn.isdirectory(M.db_dir) == 0 then
	local path = vim.fn.expand(M.db_dir)
	vim.fn.mkdir(path, "p")
end
-- end

--- Merge the user configuration with the default values.
---@param config table<string, any> user configuration
function M.resolve(config)
	config = config or {}
	M.config = vim.tbl_deep_extend("keep", config, default)
end

return M