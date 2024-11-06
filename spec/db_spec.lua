local config = require "feed.config"
config.db_dir = "~/.feed.nvim.test/"
local db = require "feed.db"
local eq = assert.are.same

describe("initialize", function()
   it("should make parent dir and data dir in the passed in path", function()
      eq(1, vim.fn.isdirectory(db.dir))
   end)
   it("should write an index file in the passed in path", function()
      eq(1, vim.fn.filereadable(db.dir .. "/index.lua"))
   end)

   it("should read index file as a table in memory", function()
      assert(db.index.version == "0.3")
   end)
end)

describe("add", function()
   it("add feed.entry to index", function()
      local entry = {
         link = "https://example.com",
         pubDate = "Fri, 30 Aug 2024 11:01:51 +0800",
         title = "zig",
         content = "zig is a programming language",
         id = "1234567",
      }
      db:add(entry)
      db:save()
      local expected = vim.deepcopy(entry)
      expected.content = nil
      assert.same(expected, dofile(db.dir .. "/index.lua")[entry.id])
   end)
end)
