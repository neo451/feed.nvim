local M = {}
local Job = require("plenary.job")
local flatdb = require("db")
local db = flatdb("/home/n451/Plugins/rss.nvim/lua/data")

local xml2lua = require("xml")
local handler = require("tree")

local function find_root(tbl)
	return tbl
end

---fetch xml from source and load them into db
---@param url any
---@param name string # name of the source
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
			print(name, url, vim.inspect(self:result()))
			if #self:result() > 3 then
				src = table.concat(self:result(), " ")
			else
				src = self:result()[2]
			end
			parser:parse(src)
			pp(hdlr.root)
			local root = find_root(hdlr.root)
			for i, item in ipairs(root) do
				pp(item)
				item.feed = hdlr.root.rss.channel.title
				item.tags = { "unread" } -- HACK:
				db[item.title] = item
				table.insert(db[name], item.title)
				table.insert(db.titles, item.title)
			end
			db:save()
		end,
	}):start()
end

-- M.update_feed("http://blog.devtang.com/atom.xml", "devtang")

return M
