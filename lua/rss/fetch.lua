local config = require("rss.config")
local flatdb = require("rss._db")
local xml = require("rss.xml")
-- local db = flatdb(config.db_dir)
local db = flatdb(".rss.nvim.test")

local M = {}

---@param ast table
---@param feed_type rss.feed_type
---@return rss.entry[]
---@return string
local function get_root(ast, feed_type)
	if feed_type == "json" then
		return ast.items, ast.title
	elseif feed_type == "rss" then
		return ast.channel.item, ast.title
	end
end


---fetch xml from source and load them into db
---@param feed rss.feed
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
			local ok, ast, feed_type = pcall(xml.parse_feed, src)
			if not ok then -- FOR DEBUG
				print(("[rss.nvim] failed to parse %s"):format(feed.name or url))
				return
			end
			local entries, feed_name = get_root(ast, feed_type)
			for _, entry in ipairs(entries) do
				entry.feed = feed_name
				entry.tags = { unread = true } -- HACK:
				db:add(entry)
			end
			db:save()
		end,
	})
end

M.update_feed("https://www.jsonfeed.org/feed.json")

-- TODO:  vim.notify("feeds all loaded")
-- TODO:  maybe use a process bar like fidget.nvim

return M
