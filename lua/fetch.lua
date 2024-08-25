local Job = require("plenary.job")
local flatdb = require("db")

local db = flatdb("./db")

-- TODO: test speed with tree-sitter parsing!
local xml2lua = require("xml")
local handler = require("tree")

---fetch xml from source
---@param url any
local function get_contents(url, name)
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
				-- print(hdlr.root.rss.channel.title)
				db[item.title] = item
				table.insert(db[name], item.title)
				table.insert(db.titles, item.title)
			end
			db:save()
		end,
	}):start() -- or start()
end

local tests = {
	["少数派"] = "https://sspai.com/feed",
	arch = "https://archlinux.org/feeds/news/",
	["机核"] = "https://www.gcores.com/rss",
	zig = "https://andrewkelley.me/rss.xml",
	bbc = "https://feeds.bbci.co.uk/news/world/rss.xml",
}

for name, v in pairs(tests) do
	get_contents(v, name)
end
