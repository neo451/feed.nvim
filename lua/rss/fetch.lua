local M = {}
local config = require("rss.config")
local flatdb = require("rss._db")
local db = flatdb(config.db_dir)
local xml = require("rss.xml")

---fetch xml from source and load them into db
---@param feed string | table
---@param total number # total number of feeds
---@param index number # index of the feed
function M.update_feed(feed, total, index)
	local url
	if type(feed) == "table" then
		url = feed[1]
	else
		url = feed
	end
	local curl = require("rss.curl")
	curl.get({
		url = url,
		callback = function(res)
			if res.status ~= 200 then
				return
			end
			local src = res.body
			local ok, ast = pcall(xml.parse, src)
			if not ok then
				print(("[rss.nvim] failed to parse %s"):format(feed.name or url))
				return
			end
			local root, feed = ast.channel.item, ast.channel.title
			for _, entry in ipairs(root) do
				entry.feed = feed
				entry.tags = { unread = true } -- HACK:
				db:add(entry)
			end
			db:save()
		end,
	})
end

-- TODO:  vim.notify("feeds all loaded")
-- TODO:  maybe use a process bar like fidget.nvim

return M
