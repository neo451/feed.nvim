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
		print(db.dir .. "/index")
		-- assert.same(1, vim.fn.filereadable(db.dir .. "/index"))
	end)
end)
