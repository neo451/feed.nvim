local ldb = require("rss._db")

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

describe("add", function()
	local path = "~/.rss.nvim.test"
	local db = ldb(path)
	it("add rss.entry to index", function()
		local entry = {
			link = "https://example.com",
			pubDate = "2021-10-10",
			title = "zig",
			description = "zig is a programming language",
		}
		db:add(entry)
		db:save()
		assert.same(1, #db.index)
		-- print(db.index[1].id)
		assert.same("zig is a programming language", vim.fn.readfile(db:address(db.index[1]))[1])
		assert.same({ version = "0.1", entry }, vim.fn.readfile(db.dir .. "/index")[1])
	end)
end)

describe("sort", function()
	local path = "~/.rss.nvim.test"
	local db = ldb(path)
	it("add rss.entry to index", function() end)
end)
