local config = require "feed.config"
config.db_dir = "~/.feed.nvim.test/"
local db = require("feed.db").new()
local eq = assert.are.same
local dir = vim.fs.normalize(config.db_dir)
local ut = require "feed.utils"

describe("initialize", function()
   it("should make parent dir and data dir in the passed in path", function()
      eq(1, vim.fn.isdirectory(dir))
      eq(1, vim.fn.isdirectory(dir .. "/object/"))
      eq(1, vim.fn.isdirectory(dir .. "/data/"))
   end)
   it("should write an index file in the passed in path", function()
      eq(1, vim.fn.filereadable(dir .. "/feeds.lua"))
   end)

   it("should read index file as a table in memory", function()
      assert.is_table(db.feeds)
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
      assert.same(entry, db["1234567"])
      assert.same("zig is a programming language", db:read_entry "1234567")
   end)
end)

describe("iter", function()
   it("iterater over all entries", function()
      local entry = {
         link = "https://example.com",
         pubDate = "Fri, 30 Aug 2024 11:01:51 +0800",
         title = "zig",
         content = "zig is a programming language",
         id = "1",
      }

      local entry2 = {
         link = "https://example.com",
         pubDate = "Fri, 30 Aug 2024 11:01:51 +0800",
         title = "zig",
         content = "zig is a programming language",
         id = "2",
      }
      db:add(entry)
      db:add(entry2)
      for id, v in db:iter() do
         assert.is_string(id)
         assert.is_table(v)
      end
      db:blowup()
   end)
end)
