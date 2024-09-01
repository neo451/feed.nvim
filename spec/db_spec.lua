local ldb = require("rss._db")

local path = "~/.rss.nvim.test"
local db = ldb(path)
db:blowup()

describe("initialize", function()
	it("should make parent dir and data dir in the passed in path", function()
		local path = "~/.rss.nvim.test"
		local db = ldb(path)
		assert.same(1, vim.fn.isdirectory(db.dir))
	end)
	it("should write an index file in the passed in path", function()
		local path = "~/.rss.nvim.test"
		local db = ldb(path)
		assert.same(1, vim.fn.filereadable(db.dir .. "/index"))
	end)

	it("should read index file as a table in memory", function()
		local path = "~/.rss.nvim.test"
		local db = ldb(path)
		assert.same({ version = "0.1" }, db.index)
	end)
end)

db:blowup()

describe("add", function()
	local path = "~/.rss.nvim.test"
	local db = ldb(path)
	it("add rss.entry to index", function()
		local entry = {
			link = "https://example.com",
			pubDate = "Fri, 30 Aug 2024 11:01:51 +0800",
			title = "zig",
			description = "zig is a programming language",
		}
		db:add(entry)
		db:save()
		assert.same(1, #db.index)
		--TODO:
		local path_for_index_one = db:address(db.index[1])
		-- print(path_for_index_one)
		-- assert.same("zig is a programming language", vim.fn.readfile(path_for_index_one))
		-- assert.same({ version = "0.1", entry }, loadstring("return " .. vim.fn.readfile(db.dir .. "/index")[1])())
	end)
end)

db:blowup()

describe("sort", function()
	local path = "~/.rss.nvim.test"
	local db = ldb(path)
	it("add rss.entry to index", function()
		db:add({
			link = "https://example.com",
			title = "1111",
			pubDate = "Fri, 30 Aug 2022 11:01:51 +0800",
			description = "early",
		})
		db:add({
			link = "https://example2.com",
			title = "2222",
			pubDate = "Fri, 30 Aug 2024 11:01:51 +0800",
			description = "late",
		})
		assert.same("1111", db.index[1].title)
		assert.same("2222", db.index[2].title)
		db:sort()
		assert.same("1111", db.index[2].title)
		assert.same("2222", db.index[1].title)
		db:save()
	end)
end)
