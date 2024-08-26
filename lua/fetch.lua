local M = {}
local Job = require("plenary.job")
local flatdb = require("db")
local db = flatdb("/home/n451/Plugins/rss.nvim/lua/data")

-- TODO: test speed with tree-sitter parsing!
local xml2lua = require("xml")
local handler = require("tree")

---fetch xml from source and load them into db
---@param url any
---@param name string # name of the source # TODO: remove?
function M.update_feed(url, name)
	Job:new({
		command = "curl",
		args = { url },
		on_exit = function(self, code, signal)
			local hdlr = handler:new()
			local parser = xml2lua.parser(hdlr)
			if not db[name] then
				db[name] = {}
			end
			if not db.titles then
				db.titles = {}
			end
			local src
			if #self:result() > 3 then
				src = table.concat(self:result(), " ")
			else
				src = self:result()[2]
			end
			parser:parse(src)
			for i, item in ipairs(hdlr.root.rss.channel.item) do
				item.feed = hdlr.root.rss.channel.title
				item.tags = { "unread" } -- HACK:
				db[item.title] = item
				table.insert(db[name], item.title)
				table.insert(db.titles, item.title)
			end
			db:save()
		end,
	}):start() -- or start()
end

return M
