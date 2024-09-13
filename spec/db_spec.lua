package.path = package.path .. ";/home/n451/.local/share/nvim/lazy/plenary.nvim/lua/?.lua"

local flatdb = require "feed.db"
local eq = assert.are.same
local path = "~/.rss.nvim.test"
flatdb.prepare_db(path)
local db = flatdb.db(path)

describe("initialize", function()
   local path = "~/.rss.nvim.test"
   local db = flatdb.db(path)
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
   local path = "~/.rss.nvim.test"
   local db = flatdb.db(path)
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
      print(path_for_index_one)
      assert.same("zig is a programming language", vim.fn.readfile(path_for_index_one)[1])
      entry.id = require "rss.sha1" (entry.link)
      entry.description = nil
      assert.same({ version = "0.1", entry }, loadfile(db.dir .. "/index")())
   end)
end)

describe("sort", function()
   local path = "~/.rss.nvim.test"
   local db = flatdb.db(path)
   it("add rss.entry to index", function()
      db:add {
         link = "https://example.com",
         title = "1111",
         pubDate = "Fri, 30 Aug 2022 11:01:51 +0800",
         description = "early",
      }
      db:add {
         link = "https://example2.com",
         title = "2222",
         pubDate = "Fri, 30 Aug 2024 11:01:51 +0800",
         description = "late",
      }
      assert.same("1111", db.index[1].title)
      assert.same("2222", db.index[2].title)
      db:sort()
      assert.same("1111", db.index[2].title)
      assert.same("2222", db.index[1].title)
      db:save()
   end)
end)
--
-- -- describe("get", function()
-- --    local path = "~/.local/share/nvim/rss/.rss.nvim"
-- --    local db = ldb(path)
-- --    it("add rss.entry to index", function()
-- --       pp(db:get(db.index[1]))
-- --    end)
-- -- end)
