-- package.path = package.path .. ";/home/n451/.local/share/nvim/lazy/plenary.nvim/lua/?.lua"

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
      assert.same({ version = "0.1", entry }, loadfile(db.dir .. "/index")())
   end)
end)

describe("sort", function()
   db:blowup()
   db:update_index()
   print(vim.inspect(db.index))
   -- db:update_index()
   -- db = flatdb(path)
   it("sort entry by time", function()
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
      assert.same("1111", db.index[1].title)
      assert.same("2222", db.index[2].title)
      db:sort()
      assert.same("1111", db.index[2].title)
      assert.same("2222", db.index[1].title)
   end)
end)

describe("at", function()
   it("get content of feed.entry by index", function()
      eq("early", db:at(2))
   end)
   it("get obj of feed.entry by index", function()
      assert.is_table(db[2])
      db:blowup() -- rm the local test db
   end)
end)
