vim.treesitter.language.add("xml", {
   path = vim.fn.expand "~/.luarocks/lib/luarocks/rocks-5.1/tree-sitter-xml/0.0.29-1/parser/xml.so",
})
local config = require "feed.config"
config.db_dir = "~/.feed.nvim.test/"
local db = require "feed.db"
local eq = assert.are.same

describe("initialize", function()
   it("should make parent dir and data dir in the passed in path", function()
      eq(1, vim.fn.isdirectory(db.dir))
   end)
   it("should write an index file in the passed in path", function()
      eq(1, vim.fn.filereadable(db.dir .. "/index"))
   end)

   it("should read index file as a table in memory", function()
      assert(db.index.version == "0.1")
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
      assert.same(1, #db.index)
      local path_for_index_one = db:address(db.index[1])
      assert.same("zig is a programming language", vim.fn.readfile(path_for_index_one)[1])
      entry.description = nil
      local saved_entry = entry
      saved_entry.content = nil
      assert.same(entry, dofile(db.dir .. "/index")[1])
   end)
end)
--
-- describe("sort", function()
--    db:blowup()
--    db:update_index()
--    it("sort entry by time", function()
--       assert.same("1111", db[1].title)
--       assert.same("2222", db[2].title)
--       db:sort()
--       assert.same("1111", db[2].title)
--       assert.same("2222", db[1].title)
--    end)
-- end)
--
describe("at", function()
   db:add {
      link = "https://example.com",
      title = "1111",
      id = "1111",
      time = 1233,
      content = "early",
   }
   db:add {
      link = "https://example2.com",
      title = "2222",
      id = "2222",
      time = 1234,
      content = "late",
   }
   it("get content of feed.entry by index", function()
      eq("early", db:at(2))
   end)
   it("get obj of feed.entry by index", function()
      assert.is_table(db[2])
   end)
end)

describe("lookup", function()
   it("do efficient lookup by id", function()
      local entry = db.index[#db.index]
      local id = entry.id
      assert.same(entry, db:lookup(id))
      db:blowup() -- rm the local test db
   end)
end)
