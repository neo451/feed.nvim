local render = require("rss.render")
local fetch = require("rss.fetch")
local opml = require("rss.opml")
local config = require("rss.config")
local ut = require("rss.utils")
local actions = require("rss.actions")
local db = require("rss.db")
local telescope = require("rss.telescope")

local M = {}

local autocmds = {}

function autocmds.load_opml(file)
	local feeds = opml.parse_opml(file)
	for _, feed in ipairs(feeds) do
		local item = feed._attr
		local title = item.title
		local xmlUrl = item.xmlUrl
		config.feeds[title] = xmlUrl
	end
end

-- actions.load_opml("/home/n451/Plugins/rss.nvim/lua/list.opml")

function autocmds.list_feeds()
	print(vim.inspect(vim.tbl_values(config.feeds)))
end

function autocmds.update()
	local n = 1
	local len = vim.tbl_count(config.feeds)
	for _, link in pairs(config.feeds) do
		fetch.update_feed(link, len, n)
		n = n + 1
	end
end

-- TODO: autocomp names/url when using usrcmd
-- function autocmds.update_feed(name)
-- 	fetch.update_feed(config.feeds[name], name, 1, 1)
-- end

vim.api.nvim_create_user_command("Rss", function(opts)
	if #opts.fargs > 1 then -- TODO:
		error("too much args!")
	else
		autocmds[opts.args]()
	end
end, { nargs = 1 })

vim.api.nvim_create_autocmd("VimLeavePre", {
	pattern = "*.md",
	callback = function()
		print("leave!")
		db:save()
		-- autocmds.update()
	end,
})

local function prepare_bufs()
	render.buf = {
		index = vim.api.nvim_create_buf(false, true),
		entry = {},
	}
	for i = 1, 3 do
		render.buf.entry[i] = vim.api.nvim_create_buf(false, true)
		for rhs, lhs in pairs(config.entry_keymaps) do
			ut.push_keymap(render.buf.entry[i], lhs, actions.entry[rhs])
		end
	end
	for rhs, lhs in pairs(config.index_keymaps) do
		ut.push_keymap(render.buf.index, lhs, actions.index[rhs])
	end
end

function M.setup(user_config)
	config.resolve(user_config)
	config.og_colorscheme = vim.cmd("colorscheme")
	prepare_bufs()

	vim.keymap.set("n", "<leader>rt", telescope.show_telescope, { desc = "Show [R]ss feed in [T]elescope" })
	vim.keymap.set("n", "<leader>rs", render.show_index, { desc = "Show [R][s]s feed" })
end

return M
