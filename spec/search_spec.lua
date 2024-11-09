local M = require "feed.search"
local date = require "feed.date"
local config = require "feed.config"
config.db_dir = "~/.feed.nvim.test/"
local db = require("feed.db").new()

function DB(entries)
   for i, v in ipairs(entries) do
      v.content = ""
      v.id = i
      v.time = v.time or i
      db:add(v)
   end
end

describe("parse_query", function()
   it("should split query into parts", function()
      local query = M.parse_query "+read -star @5-days-ago linu[xs]"
      local expected =
         { must_have = { "read" }, must_not_have = { "star" }, after = date.today:days_ago(5):absolute(), before = date.today:absolute(), re = { vim.regex "linu[xs]" } }
      assert.same(expected.must_have, query.must_have)
      assert.same(expected.must_not_have, query.must_not_have)
      assert.same(expected.after, query.after)
      assert.same(expected.before, query.before)
      assert.same(type(expected.re), type(query.re))
   end)
end)

describe("filter", function()
   it("return identical if query empty", function()
      DB {
         { title = "hi", tags = { unread = true, star = true } },
      }
      local res = db:filter ""
      assert.same({ "1" }, res)
   end)

   it("filter by tags", function()
      DB {
         { tags = { unread = true, star = true }, time = 1, id = 1 },
         { tags = { unread = true }, time = 2, id = 2 },
         { tags = { star = true }, time = 3, id = 3 },
         { tags = {}, time = 4, id = 4 },
         { tags = { unread = true }, time = 2, id = 5 },
      }
      local res = db:filter "+unread -star"
      assert.same({ "2", "5" }, res)
   end)

   it("filter by date", function()
      DB {
         { time = date.today:days_ago(6):absolute(), v = 6 },
         { time = date.today:days_ago(7):absolute(), v = 7 },
         { time = date.today:days_ago(1):absolute(), v = 1 },
         { time = date.today:absolute(), v = 0, id = 4 },
      }
      local res = db:filter "@5-days-ago"
      assert.same({ "4", "3" }, res)
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
      assert.same({ "1", "2" }, res)
      local res2 = db:filter "!Neo !vim"
      assert.same({ "5" }, res2)
   end)

   it("filter by limit number", function()
      local entries = {}
      for i = 1, 20 do
         entries[i] = { title = i, time = i, id = i }
      end
      DB(entries)
      local res = db:filter "#10"
      assert.same(10, #res)
   end)

   it("filter by feed", function()
      db:blowup()
      DB {
         { feed = "neovim.io" },
         { feed = "ovim.io" },
         { feed = "vm.io" },
      }
      local res = db:filter "=vim"
      -- assert.same(2, #res)
   end)
end)
