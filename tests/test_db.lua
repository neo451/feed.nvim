local config = require "feed.config"
config.db_dir = "~/.feed.nvim.test/"
local ut = require "feed.utils"
local db = ut.require "feed.db"
local date = require "feed.parser.date"
local eq = MiniTest.expect.equality

describe("initialize", function()
   local dir = tostring(db.dir)
   it("should make parent dir and data dir in the passed in path", function()
      eq(1, vim.fn.isdirectory(dir))
      eq(1, vim.fn.isdirectory(dir .. "/object/"))
      eq(1, vim.fn.isdirectory(dir .. "/data/"))
   end)
   it("should write an index file in the passed in path", function()
      eq(1, vim.fn.filereadable(dir .. "/feeds.lua"))
   end)

   it("should read index file as a table in memory", function()
      eq("table", type(db.feeds))
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
         time = 1,
      }
      db:add(entry)
      entry.content = nil
      entry.id = nil
      eq(entry, db["1234567"])
      eq("zig is a programming language", table.concat(vim.fn.readfile(tostring(db.dir) .. "/data/" .. "1234567")))
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
         time = 1,
      }

      local entry2 = {
         link = "https://example.com",
         pubDate = "Fri, 30 Aug 2024 11:01:51 +0800",
         title = "zig",
         content = "zig is a programming language",
         id = "2",
         time = 2,
      }
      db:add(entry)
      db:add(entry2)
      for id, v in db:iter() do
         eq("string", type(id))
         eq("table", type(v))
      end
   end)

   it("iterater over all entries ordered by time", function()
      local entry = {
         link = "https://example.com",
         pubDate = "Fri, 30 May 2024 11:01:51 +0800",
         title = "zig",
         content = "zig is a programming language",
         id = "1",
      }

      local entry2 = {
         link = "https://example.com",
         pubDate = "Fri, 2 Aug 2024 11:01:51 +0800",
         title = "zig",
         content = "zig is a programming language",
         id = "2",
      }
      db:add(entry)
      db:add(entry2)
      local res = {}
      db:sort()
      for _, v in db:iter(true) do
         table.insert(res, v.time)
      end
      assert(res[1] > res[2])
   end)
end)

describe("tag", function()
   it("tag entry", function()
      local entry = {
         link = "https://example.com",
         time = 1,
         title = "zig",
         content = "zig is a programming language",
         id = "1",
      }

      db:add(entry)
      db:tag("1", "star")
      eq(db.tags.star["1"], true)
      eq(db["1"].tags.star, true)
      db:untag("1", "star")
      eq(nil, db.tags.star["1"])
      eq(nil, db["1"].tags.star)
   end)
end)

describe("filter", function()
   local function clear()
      for id, _ in db:iter() do
         db:rm(id)
      end
   end
   function DB(entries)
      clear()
      for i, v in ipairs(entries) do
         v.content = ""
         v.id = tostring(i)
         v.time = v.time or i
         db:add(v)
      end
   end
   it("return identical if query empty", function()
      DB {
         { title = "hi" },
         { title = "hello" },
      }
      db:tag("1", "unread")
      db:tag("1", "star")
      local res = db:filter ""
      eq({ "2", "1" }, res)
      clear()
   end)

   it("filter by tags", function()
      DB { {}, {}, {}, {}, {} }
      db:tag("1", "read")
      db:tag("1", "star")
      db:tag("2", "read")
      db:tag("3", "star")
      db:tag("5", "read")
      local res = db:filter "+read -star"
      eq({ "5", "2" }, res)
      db:untag("1", "unread")
      db:untag("1", "star")
      db:untag("2", "unread")
      db:untag("3", "star")
      db:untag("5", "unread")
   end)

   it("filter by date", function()
      DB {
         { time = date.days_ago(6) },
         { time = date.days_ago(7) },
         { time = date.days_ago(1) },
         { time = os.time() },
      }
      db:sort()
      local res = db:filter "@5-days-ago"
      eq({ "4", "3" }, res)
   end)

   it("filter by limit number", function()
      local entries = {}
      for i = 1, 20 do
         entries[i] = { title = i, time = i, id = i }
      end
      DB(entries)
      local res = db:filter "#10"
      eq(10, #res)
   end)

   it("filter by regex", function()
      DB {
         { title = "Neovim is awesome", time = 1 },
         { title = "neovim is lowercase", time = 1 },
         { title = "Vim is awesome", time = 1 },
         { title = "vim is lowercase", time = 1 },
         { title = "bim is not a thing", time = 1 },
      }
      local res = db:filter "Neo vim"
      eq({ "1", "2" }, res)
      -- local res2 = db:filter "!Neo !vim"
      -- eq({ "5" }, res2)
   end)

   it("filter by feed", function()
      DB {
         { feed = "neovim.io" },
         { feed = "ovim.io" },
         { feed = "vm.io" },
      }
      local res = db:filter "=vim"
      eq(2, #res)
      db:blowup()
   end)
end)
