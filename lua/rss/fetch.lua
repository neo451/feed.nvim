local M = {}
local config = require("rss.config")
local flatdb = require("rss.db")
local db = flatdb(config.db_dir)
local xml = require("rss.xml")

-- if not db.index then
-- 	db.index = {}
-- end

---fetch xml from source and load them into db
---@param url string
---@param total number # total number of feeds
---@param index number # index of the feed
function M.update_feed(url, total, index)
	if not db[url] then
		db[url] = {}
	end
	local curl = require "plenary.curl"
	-- local curl = require("rss.curl")
	curl.get({
		url = url,
		callback = function(res)
			if res.status ~= 200 then
				return
			end
			local src = res.body
			src = src:gsub("\n")
			print(src)
			-- local ast = xml.parse(src)
			-- local root, feed = ast.channel.item, ast.channel.title
			-- for _, item in ipairs(root) do
			-- 	item.feed = feed
			-- 	item.tags = { unread = true } -- HACK:
			-- 	db[item.title] = item
			-- 	table.insert(db.index, item.title)
			-- end
			-- db:save()
			-- vim.schedule_wrap(function()
			-- 	vim.notify(("[rss.nvim] [%d/%d] loaded %s"):format(index, total, feed))
			-- end)()
			-- vim.notify(("[rss.nvim] [%d/%d] loaded %s"):format(index, total, feed))
		end,
	})
end

-- TODO:  vim.notify("feeds all loaded")
-- TODO:  maybe use a process bar like fidget.nvim

return M
