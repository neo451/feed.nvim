local render = require("rss.render")
local fetch = require("rss.fetch")
local opml = require("rss.opml")
local config = require("rss.config")

local M = {}

M._feeds = {
	["少数派"] = "https://sspai.com/feed",
	-- arch = "https://archlinux.org/feeds/news/",
	["机核"] = "https://www.gcores.com/rss",
	-- zig = "https://andrewkelley.me/rss.xml",
	-- bbc = "https://feeds.bbci.co.uk/news/world/rss.xml",
}

local actions = {}

function actions.load_opml(file)
	local feeds = opml.parse_opml(file)
	for _, feed in ipairs(feeds) do
		local item = feed._attr
		local title = item.title
		local xmlUrl = item.xmlUrl
		M._feeds[title] = xmlUrl
	end
end

-- actions.load_opml("/home/n451/Plugins/rss.nvim/lua/list.opml")

function actions.list_feeds()
	print(vim.inspect(M._feeds))
end

function actions.update()
	for name, link in pairs(M._feeds) do
		fetch.update_feed(link, name)
	end
end

-- TODO: autocomp when using usrcmd
function actions.update_feed(name)
	fetch.update_feed(M._feeds[name], name)
end

vim.api.nvim_create_user_command("Rss", function(opts)
	if #opts.fargs > 1 then -- TODO:
		error("too much args!")
	else
		actions[opts.args]()
	end
end, { nargs = 1 })

function M.setup(user_config)
	config.resolve(user_config)
	render.setup()
	vim.keymap.set("n", "<leader>rt", render.render_telescope, { desc = "Show [R]ss feed in [T]elescope" })
	vim.keymap.set("n", "<leader>rs", render.render_index, { desc = "Show [R][s]s feed" })
end

return M
